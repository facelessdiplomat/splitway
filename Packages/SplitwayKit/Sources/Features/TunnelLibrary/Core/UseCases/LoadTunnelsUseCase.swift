public struct LoadTunnelsUseCase: Sendable {
    private let persistence: TunnelPersistence

    public init(records: any TunnelRecordRepository, secrets: any TunnelSecretStore) {
        persistence = TunnelPersistence(records: records, secrets: secrets)
    }

    public func execute() async throws(TunnelLibraryError) -> TunnelLibrarySnapshot {
        var entries: [TunnelLibraryEntry] = []
        for record in try await persistence.records.loadRecords() {
            do {
                entries.append(.readable(try await persistence.tunnel(for: record)))
            } catch .unreadableConfiguration, .storage(.missingConfiguration), .storage(.corruptedData) {
                entries.append(.unreadable(record))
            }
        }
        return TunnelLibrarySnapshot(entries: entries)
    }
}
