public protocol TunnelSecretStore: Sendable {
    func loadConfigurationText(for tunnel: TunnelIdentifier) async throws(TunnelStorageError) -> String
    func saveConfigurationText(_ text: String, for tunnel: TunnelIdentifier) async throws(TunnelStorageError)
    func deleteConfigurationText(for tunnel: TunnelIdentifier) async throws(TunnelStorageError)
}
