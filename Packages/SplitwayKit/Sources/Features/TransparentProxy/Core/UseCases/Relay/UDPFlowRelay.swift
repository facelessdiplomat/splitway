import Foundation
import SharedKernel
import Synchronization
import TunnelEngine

public final class UDPFlowRelay: Sendable {
    public static let windowDatagramCount = 4

    private struct State: Sendable {
        var associations: UDPAssociationTable<FlowEndpoint, any UserspaceConnection>
        var onFinish: (@Sendable () -> Void)?
        var lastActivity: Date
        var isFinished = false
    }

    private let flow: any ProxiedDatagramFlow
    private let network: any RunningUserspaceNetwork
    private let policy: UDPRelayPolicy
    private let clock: any WallClock
    private let destination: @Sendable (FlowEndpoint) -> UserspaceNetworkDestination?
    private let replyObserver: (@Sendable (ProxiedDatagram) -> Void)?
    private let queue: DispatchQueue
    private let state: Mutex<State>

    public init(
        flow: any ProxiedDatagramFlow,
        network: any RunningUserspaceNetwork,
        policy: UDPRelayPolicy,
        environment: RelayEnvironment,
        replyObserver: (@Sendable (ProxiedDatagram) -> Void)? = nil,
        destination: @escaping @Sendable (FlowEndpoint) -> UserspaceNetworkDestination?
    ) {
        self.flow = flow
        self.network = network
        self.policy = policy
        self.destination = destination
        self.replyObserver = replyObserver
        clock = environment.clock
        queue = DispatchQueue(label: "Splitway.UDPFlowRelay", target: environment.targetQueue)
        state = Mutex(State(associations: UDPAssociationTable(policy: policy), lastActivity: environment.clock.now()))
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
        let (expired, isFlowIdle) = state.withLock { state -> ([any UserspaceConnection], Bool) in
            guard !state.isFinished else { return ([], false) }
            let expired = state.associations.removeExpired(at: moment)
            let idleTime = Duration.seconds(moment.timeIntervalSince(state.lastActivity))
            return (expired, state.associations.isEmpty && idleTime >= policy.idleTimeout)
        }
        for association in expired {
            association.close(.both)
        }
        guard isFlowIdle else { return false }
        finish(with: nil)
        return true
    }

    func deliverReply(
        _ bytes: UnsafeRawBufferPointer, from endpoint: FlowEndpoint, through association: any UserspaceConnection
    ) {
        let datagram = ProxiedDatagram(payload: Data(bytes), remoteEndpoint: endpoint)
        let now = clock.now()
        let isActive = state.withLock { state -> Bool in
            guard !state.isFinished else { return false }
            state.associations.recordActivity(for: endpoint, at: now)
            state.lastActivity = now
            return true
        }
        guard isActive else { return }
        replyObserver?(datagram)
        flow.writeDatagrams([datagram]) { error in
            if let error {
                self.queue.async { self.finish(with: error) }
            } else {
                association.grant(datagram.payload.count)
            }
        }
    }

    private func readFromApp() {
        flow.readDatagrams { result in
            self.queue.async { self.forwardToTunnel(result) }
        }
    }

    private func forwardToTunnel(_ result: Result<[ProxiedDatagram], ProxiedFlowError>) {
        switch result {
        case .failure(let error):
            finish(with: error)
        case .success(let datagrams) where datagrams.isEmpty:
            finish(with: nil)
        case .success(let datagrams):
            for datagram in datagrams {
                send(datagram)
            }
            readFromApp()
        }
    }

    private func send(_ datagram: ProxiedDatagram) {
        guard let association = association(for: datagram.remoteEndpoint) else { return }
        let written = datagram.payload.withUnsafeBytes { bytes in
            Result { () throws(UserspaceNetworkError) in try association.write(bytes) }
        }
        guard case .failure = written else { return }
        let removed = state.withLock { state in state.associations.remove(datagram.remoteEndpoint) }
        removed?.close(.both)
    }

    private func association(for endpoint: FlowEndpoint) -> (any UserspaceConnection)? {
        let now = clock.now()
        if let existing = existingAssociation(for: endpoint, at: now) {
            return existing
        }
        guard let target = destination(endpoint), let opened = try? network.openUDP(to: target) else { return nil }
        let receiver = UDPRelayReplyReceiver(relay: self, endpoint: endpoint, association: opened)
        do {
            try opened.startReceiving(
                into: receiver,
                readByteCount: policy.datagramBufferByteCount,
                initialCredit: policy.datagramBufferByteCount * Self.windowDatagramCount
            )
        } catch {
            opened.close(.both)
            return nil
        }
        return adopt(opened, for: endpoint, at: now)
    }

    private func existingAssociation(for endpoint: FlowEndpoint, at moment: Date) -> (any UserspaceConnection)? {
        state.withLock { state -> (any UserspaceConnection)? in
            guard !state.isFinished, let existing = state.associations.association(for: endpoint) else { return nil }
            state.associations.recordActivity(for: endpoint, at: moment)
            state.lastActivity = moment
            return existing
        }
    }

    private func adopt(
        _ association: any UserspaceConnection,
        for endpoint: FlowEndpoint,
        at moment: Date
    ) -> (any UserspaceConnection)? {
        let (departed, isAdopted) = state.withLock { state -> ((any UserspaceConnection)?, Bool) in
            guard !state.isFinished else { return (nil, false) }
            state.lastActivity = moment
            return (state.associations.insert(association, for: endpoint, at: moment), true)
        }
        departed?.close(.both)
        guard isAdopted else {
            association.close(.both)
            return nil
        }
        return association
    }

    private func finish(with error: ProxiedFlowError?) {
        let finishing = state.withLock { state -> RelayFinishing? in
            guard !state.isFinished else { return nil }
            state.isFinished = true
            return RelayFinishing(connections: state.associations.removeAll(), onFinish: state.onFinish)
        }
        guard let finishing else { return }
        finishing.closeConnections()
        flow.closeRead(with: error)
        flow.closeWrite(with: error)
        finishing.onFinish?()
    }
}
