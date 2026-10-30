import DNSProxy
import Foundation
import SharedKernel
import Synchronization

public final class DNSRefusalRelay: FlowRelay {
    private struct State: Sendable {
        var onFinish: (@Sendable () -> Void)?
        var lastActivity: Date
        var isFinished = false
    }

    private let flow: any ProxiedDatagramFlow
    private let policy: UDPRelayPolicy
    private let clock: any WallClock
    private let queue: DispatchQueue
    private let state: Mutex<State>

    public init(flow: any ProxiedDatagramFlow, policy: UDPRelayPolicy, environment: RelayEnvironment) {
        self.flow = flow
        self.policy = policy
        clock = environment.clock
        queue = DispatchQueue(label: "Splitway.DNSRefusalRelay", target: environment.targetQueue)
        state = Mutex(State(lastActivity: environment.clock.now()))
    }

    public func start(onFinish: @escaping @Sendable () -> Void) {
        let now = clock.now()
        state.withLock { state in
            state.onFinish = onFinish
            state.lastActivity = now
        }
        flow.open { error in
            self.queue.async {
                if let error {
                    self.finish(with: error)
                } else {
                    self.readFromApp()
                }
            }
        }
    }

    public func cancel() {
        finish(with: .aborted)
    }

    public func closeIfIdle(at moment: Date) -> Bool {
        let isIdle = state.withLock { state in
            !state.isFinished && Duration.seconds(moment.timeIntervalSince(state.lastActivity)) >= policy.idleTimeout
        }
        guard isIdle else { return false }
        finish(with: nil)
        return true
    }

    private func readFromApp() {
        flow.readDatagrams { result in
            self.queue.async { self.refuse(result) }
        }
    }

    private func refuse(_ result: Result<[ProxiedDatagram], ProxiedFlowError>) {
        switch result {
        case .failure(let error):
            finish(with: error)
        case .success(let queries) where queries.isEmpty:
            finish(with: nil)
        case .success(let queries):
            let now = clock.now()
            state.withLock { state in state.lastActivity = now }
            let refusals = queries.compactMap(Self.refusal(answering:))
            if !refusals.isEmpty {
                flow.writeDatagrams(refusals) { error in
                    guard let error else { return }
                    self.queue.async { self.finish(with: error) }
                }
            }
            readFromApp()
        }
    }

    private static func refusal(answering query: ProxiedDatagram) -> ProxiedDatagram? {
        guard let response = try? DNSRefusalResponseBuilder.response(refusing: Array(query.payload)) else {
            return nil
        }
        return ProxiedDatagram(payload: Data(response), remoteEndpoint: query.remoteEndpoint)
    }

    private func finish(with error: ProxiedFlowError?) {
        let (isFirstFinish, onFinish) = state.withLock { state -> (Bool, (@Sendable () -> Void)?) in
            guard !state.isFinished else { return (false, nil) }
            state.isFinished = true
            return (true, state.onFinish)
        }
        guard isFirstFinish else { return }
        flow.closeRead(with: error)
        flow.closeWrite(with: error)
        onFinish?()
    }
}
