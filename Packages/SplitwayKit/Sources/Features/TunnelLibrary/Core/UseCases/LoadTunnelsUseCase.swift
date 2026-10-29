public struct TunnelLibrarySnapshot: Sendable, Hashable {
    public let tunnels: [Tunnel]
    public let unreadableRecords: [TunnelRecord]
}

public struct LoadTunnelsUseCase: Sendable {
    private let persistence: TunnelPersistence

    public init(records: any TunnelRecordRepository, secrets: any TunnelSecretStore) {
        persistence = TunnelPersistence(records: records, secrets: secrets)
    }

    public func execute() async throws(TunnelLibraryError) -> TunnelLibrarySnapshot {
        var tunnels: [Tunnel] = []
        var unreadableRecords: [TunnelRecord] = []
        for record in try await persistence.records.loadRecords() {
            do {
                tunnels.append(try await persistence.tunnel(for: record))
            } catch .unreadableConfiguration, .storage(.missingConfiguration), .storage(.corruptedData) {
                unreadableRecords.append(record)
            }
        }
        return TunnelLibrarySnapshot(tunnels: tunnels, unreadableRecords: unreadableRecords)
    }
}
