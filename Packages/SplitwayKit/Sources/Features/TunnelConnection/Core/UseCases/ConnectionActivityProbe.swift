import TunnelLibrary

public struct ConnectionActivityProbe: TunnelActivityProbe {
    private let controller: any SystemTunnelController
    private let coordinator: ConnectionCoordinator

    public init(controller: any SystemTunnelController, coordinator: ConnectionCoordinator) {
        self.controller = controller
        self.coordinator = coordinator
    }

    public func isActive(_ tunnel: TunnelIdentifier) async -> Bool {
        let installedTunnel = await controller.installedTunnel()
        let status = await controller.currentStatus()
        return installedTunnel == tunnel && status.isActive
    }

    public func stop(_ tunnel: TunnelIdentifier) async throws(TunnelActivityError) {
        guard await isActive(tunnel) else { return }
        await coordinator.deactivate()
        guard await !isActive(tunnel) else { throw .stopFailed }
    }
}
