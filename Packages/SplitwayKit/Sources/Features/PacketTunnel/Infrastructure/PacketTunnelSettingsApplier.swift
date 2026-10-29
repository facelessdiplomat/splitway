import NetworkExtension
import PacketTunnel

public actor PacketTunnelSettingsApplier: TunnelNetworkSettingsApplier {
    private let provider: NEPacketTunnelProvider

    public init(provider: sending NEPacketTunnelProvider) {
        self.provider = provider
    }

    public func apply(_ plan: TunnelNetworkPlan) async throws(TunnelNetworkSettingsError) {
        do {
            try await provider.setTunnelNetworkSettings(NetworkSettingsMapper.settings(for: plan))
        } catch {
            throw .rejected
        }
    }
}
