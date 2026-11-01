public protocol ErasableTunnelSecretStore: TunnelSecretStore {
    func deleteAllConfigurationTexts() async throws(TunnelStorageError)
}
