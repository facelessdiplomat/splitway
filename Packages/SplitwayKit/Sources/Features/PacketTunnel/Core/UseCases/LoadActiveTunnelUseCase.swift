import ProviderMessaging
import TunnelConfiguration
import TunnelLibrary

public struct LoadActiveTunnelUseCase: Sendable {
    private let secrets: any TunnelSecretStore

    public init(secrets: any TunnelSecretStore) {
        self.secrets = secrets
    }

    public nonisolated(nonsending) func execute(
        providerConfiguration: [String: Any]?
    ) async throws(PacketTunnelError) -> ActiveTunnel {
        guard let slot = try? TunnelProviderConfigurationCodec.configuration(from: providerConfiguration) else {
            throw .configurationUnavailable
        }
        guard let text = try? await secrets.loadConfigurationText(for: slot.tunnelID),
            let configuration = WgQuickConfigurationParser.parse(text).configuration
        else {
            throw .configurationUnavailable
        }
        return ActiveTunnel(id: slot.tunnelID, configuration: configuration, routingPolicy: slot.routingPolicy)
    }
}
