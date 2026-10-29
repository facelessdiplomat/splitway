import TunnelLibrary

public actor InMemoryTunnelSecretStore: TunnelSecretStore {
    public private(set) var texts: [TunnelIdentifier: String]
    private var failingSaveNumbers: Set<Int> = []
    private var attemptedSaveCount = 0

    public init(texts: [TunnelIdentifier: String] = [:]) {
        self.texts = texts
    }

    public func failSave(number saveNumber: Int) {
        failingSaveNumbers.insert(saveNumber)
    }

    public func loadConfigurationText(for tunnel: TunnelIdentifier) async throws(TunnelStorageError) -> String {
        guard let text = texts[tunnel] else { throw .missingConfiguration }
        return text
    }

    public func saveConfigurationText(_ text: String, for tunnel: TunnelIdentifier) async throws(TunnelStorageError) {
        attemptedSaveCount += 1
        guard !failingSaveNumbers.contains(attemptedSaveCount) else { throw .unavailable }
        texts[tunnel] = text
    }

    public func deleteConfigurationText(for tunnel: TunnelIdentifier) async throws(TunnelStorageError) {
        texts[tunnel] = nil
    }
}
