import PacketTunnel
import PacketTunnelInfrastructure

extension PacketTunnelProvider: NetworkSettingsApplier {
    nonisolated(nonsending) func apply(_ plan: TunnelNetworkPlan) async throws(PacketTunnelError) {
        do {
            try await setTunnelNetworkSettings(NetworkSettingsMapper.settings(for: plan))
        } catch {
            throw .networkSettingsRejected
        }
    }
}
