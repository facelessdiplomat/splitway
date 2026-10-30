import TunnelConnection
import TunnelLibrary

public struct SecretDeliveringTunnelController: SystemTunnelController {
    private let controller: any SystemTunnelController
    private let deliverSecret: DeliverTunnelSecretUseCase

    public init(controller: any SystemTunnelController, deliverSecret: DeliverTunnelSecretUseCase) {
        self.controller = controller
        self.deliverSecret = deliverSecret
    }

    public func installedTunnel() async -> TunnelIdentifier? {
        await controller.installedTunnel()
    }

    public func currentStatus() async -> SystemConnectionStatus {
        await controller.currentStatus()
    }

    public func statusUpdates() -> AsyncStream<SystemConnectionStatus> {
        controller.statusUpdates()
    }

    public func lastDisconnectFailure() async -> ConnectionFailure? {
        await controller.lastDisconnectFailure()
    }

    public func install(_ tunnel: Tunnel) async throws(ConnectionFailure) {
        do {
            try await deliverSecret.execute(for: tunnel.id)
        } catch {
            throw switch error {
            case .secretUnavailable: .configurationUnavailable
            case .extensionUnreachable: .extensionUnavailable
            case .rejected: .unknown
            }
        }
        try await controller.install(tunnel)
    }

    public func start() async throws(ConnectionFailure) {
        try await controller.start()
    }

    public func stop() async {
        await controller.stop()
    }
}
