import TunnelLibrary

public struct DeliverTunnelSecretUseCase: Sendable {
    private let secrets: any TunnelSecretStore
    private let channel: any ExtensionSecretChannel

    public init(secrets: any TunnelSecretStore, channel: any ExtensionSecretChannel) {
        self.secrets = secrets
        self.channel = channel
    }

    public func execute(for tunnel: TunnelIdentifier) async throws(SecretDeliveryError) {
        let configurationText: String
        do {
            configurationText = try await secrets.loadConfigurationText(for: tunnel)
        } catch {
            throw .secretUnavailable
        }
        try await channel.deliver(.store(tunnel: tunnel, configurationText: configurationText))
    }
}
