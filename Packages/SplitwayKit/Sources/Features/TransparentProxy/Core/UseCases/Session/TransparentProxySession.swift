import AppRouting
import Foundation
import PacketTunnel
import SharedKernel
import Synchronization
import TunnelEngine

public final class TransparentProxySession: Sendable {
    private let starter: TransparentProxyStarter
    private let router: ProxiedFlowRouter
    private let pathMonitor: any NetworkPathMonitor
    private let ticker: any Ticker
    private let clock: any WallClock
    private let readinessPolicy: TunnelReadinessPolicy
    private let startedAt = Mutex<Date?>(nil)
    private let observations = Mutex<[Task<Void, Never>]>([])

    public init(
        starter: TransparentProxyStarter,
        router: ProxiedFlowRouter,
        pathMonitor: any NetworkPathMonitor,
        ticker: any Ticker,
        clock: any WallClock,
        readinessPolicy: TunnelReadinessPolicy = .standard
    ) {
        self.starter = starter
        self.router = router
        self.pathMonitor = pathMonitor
        self.ticker = ticker
        self.clock = clock
        self.readinessPolicy = readinessPolicy
    }

    public func start(_ tunnel: ActiveTunnel) async throws(TransparentProxyError) -> TransparentProxyNetworkPlan {
        let runtime = try await starter.start(tunnel)
        let now = clock.now()
        startedAt.withLock { startedAt in startedAt = now }
        router.activate(runtime)
        observe(runtime)
        return runtime.plan
    }

    public var isRunning: Bool {
        router.currentRuntime != nil
    }

    public func apply(_ policy: RoutingPolicy) throws(TransparentProxyError) {
        guard let runtime = router.currentRuntime else { throw .notRunning }
        router.replaceDecider(with: try TransparentProxyStarter.decider(for: policy, plan: runtime.plan))
    }

    public func runtimeStatistics() throws(TransparentProxyError) -> RuntimeStatistics {
        guard let runtime = router.currentRuntime else { throw .notRunning }
        do {
            return try runtime.network.runtimeStatistics()
        } catch {
            throw .engineFailed(error)
        }
    }

    public func maintain(at moment: Date) {
        guard let runtime = router.currentRuntime, let start = startedAt.withLock({ startedAt in startedAt }) else {
            return
        }
        let latestHandshake = (try? runtime.network.runtimeStatistics())?.latestHandshake
        let readiness = readinessPolicy.readiness(
            latestHandshake: latestHandshake, startedAt: start, at: moment, carriesIPv6: runtime.carriesIPv6)
        router.updateReadiness(readiness)
        router.closeIdleRelays(at: moment)
    }

    public func handleStream(_ flow: any ProxiedStreamFlow, request: ProxiedFlowRequest) -> Bool {
        router.handleStream(flow, request: request)
    }

    public func handleDatagrams(_ flow: any ProxiedDatagramFlow, request: ProxiedFlowRequest) -> Bool {
        router.handleDatagrams(flow, request: request)
    }

    public func stop() async {
        let running = observations.withLock { observations in
            defer { observations = [] }
            return observations
        }
        for observation in running {
            observation.cancel()
        }
        guard let runtime = router.deactivate() else { return }
        starter.stop(runtime)
    }

    private func observe(_ runtime: TransparentProxyRuntime) {
        let (updates, ticks) = (pathMonitor.pathUpdates(), ticker.ticks())
        let (starter, clock) = (starter, clock)
        let pathObservation = Task {
            for await path in updates where path == .available {
                await starter.refreshEndpoints(of: runtime)
            }
        }
        let maintenance = Task { [weak self] in
            for await _ in ticks {
                self?.maintain(at: clock.now())
            }
        }
        let previous = observations.withLock { observations in
            defer { observations = [pathObservation, maintenance] }
            return observations
        }
        for observation in previous {
            observation.cancel()
        }
    }
}
