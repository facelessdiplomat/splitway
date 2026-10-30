import TunnelLibrary

public struct MirroredTunnelSecretStore: TunnelSecretStore {
    private let local: any TunnelSecretStore
    private let channel: any ExtensionSecretChannel
    private let reportDeliveryFailure: @Sendable (SecretDeliveryError) -> Void

    public init(
        local: any TunnelSecretStore,
        channel: any ExtensionSecretChannel,
        reportDeliveryFailure: @escaping @Sendable (SecretDeliveryError) -> Void
    ) {
        self.local = local
        self.channel = channel
        self.reportDeliveryFailure = reportDeliveryFailure
    }

    public func loadConfigurationText(for tunnel: TunnelIdentifier) async throws(TunnelStorageError) -> String {
        try await local.loadConfigurationText(for: tunnel)
    }

    public func saveConfigurationText(_ text: String, for tunnel: TunnelIdentifier) async throws(TunnelStorageError) {
        try await local.saveConfigurationText(text, for: tunnel)
        await mirror(.store(tunnel: tunnel, configurationText: text))
    }

    public func deleteConfigurationText(for tunnel: TunnelIdentifier) async throws(TunnelStorageError) {
        try await local.deleteConfigurationText(for: tunnel)
        await mirror(.remove(tunnel: tunnel))
    }

    private func mirror(_ message: SecretDeliveryMessage) async {
        do {
            try await channel.deliver(message)
        } catch {
            reportDeliveryFailure(error)
        }
    }
}
