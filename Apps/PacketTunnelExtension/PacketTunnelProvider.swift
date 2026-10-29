import NetworkExtension
import PacketTunnel
import PacketTunnelInfrastructure
import ProviderMessaging

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private let composition = PacketTunnelComposition()

    override nonisolated(nonsending) func startTunnel(options: [String: NSObject]?) async throws {
        do {
            try await startSession()
        } catch {
            composition.log.record(.error, "Tunnel failed to start: \(error)")
            if let reason = TunnelStopReason(packetTunnelError: error) {
                throw reason.error
            }
            throw CancellationError()
        }
    }

    override nonisolated(nonsending) func stopTunnel(with reason: NEProviderStopReason) async {
        composition.log.record(.info, "Tunnel stopped by the system, reason \(reason.rawValue)")
        await composition.session.stop()
    }

    override nonisolated(nonsending) func handleAppMessage(_ messageData: Data) async -> Data? {
        await composition.messageDispatcher.response(to: messageData)
    }

    override func wake() {
        let session = composition.session
        Task { await session.wake() }
    }

    private nonisolated(nonsending) func startSession() async throws(PacketTunnelError) {
        let tunnelProtocol = protocolConfiguration as? NETunnelProviderProtocol
        let activeTunnel = try await composition.loadActiveTunnel.execute(
            providerConfiguration: tunnelProtocol?.providerConfiguration
        )
        let preparedStart = try await composition.session.prepareStart(
            configuration: activeTunnel.configuration,
            routedBy: activeTunnel.routingPolicy
        )
        do {
            try await setTunnelNetworkSettings(NetworkSettingsMapper.settings(for: preparedStart.networkPlan))
        } catch {
            throw .networkSettingsRejected
        }
        try await composition.session.completeStart(preparedStart)
        composition.log.record(.info, "Tunnel started")
    }
}
