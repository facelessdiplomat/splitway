import PacketTunnel
import Synchronization

public final class TransparentProxySession: Sendable {
    private let starter: TransparentProxyStarter
    private let router: ProxiedFlowRouter
    private let pathMonitor: any NetworkPathMonitor
    private let pathObservation = Mutex<Task<Void, Never>?>(nil)

    public init(starter: TransparentProxyStarter, router: ProxiedFlowRouter, pathMonitor: any NetworkPathMonitor) {
        self.starter = starter
        self.router = router
        self.pathMonitor = pathMonitor
    }

    public func start(_ tunnel: ActiveTunnel) async throws(TransparentProxyError) -> TransparentProxyNetworkPlan {
        let runtime = try await starter.start(tunnel)
        router.activate(runtime)
        observePathChanges(of: runtime)
        return runtime.plan
    }

    public func handleStream(_ flow: any ProxiedStreamFlow, request: ProxiedFlowRequest) -> Bool {
        router.handleStream(flow, request: request)
    }

    public func handleDatagrams(_ flow: any ProxiedDatagramFlow, request: ProxiedFlowRequest) -> Bool {
        router.handleDatagrams(flow, request: request)
    }

    public func stop() async {
        let observation = pathObservation.withLock { observation in
            defer { observation = nil }
            return observation
        }
        observation?.cancel()
        guard let runtime = router.deactivate() else { return }
        await starter.stop(runtime)
    }

    private func observePathChanges(of runtime: TransparentProxyRuntime) {
        let updates = pathMonitor.pathUpdates()
        let starter = starter
        let observation = Task {
            for await path in updates where path == .available {
                await starter.refreshEndpoints(of: runtime)
            }
        }
        pathObservation.withLock { current in
            current?.cancel()
            current = observation
        }
    }
}
