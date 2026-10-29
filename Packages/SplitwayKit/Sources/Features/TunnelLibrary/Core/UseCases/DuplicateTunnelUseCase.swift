public struct DuplicateTunnelUseCase: Sendable {
    private let persistence: TunnelPersistence

    public init(records: any TunnelRecordRepository, secrets: any TunnelSecretStore) {
        persistence = TunnelPersistence(records: records, secrets: secrets)
    }

    public func execute(id: TunnelIdentifier) async throws(TunnelLibraryError) -> Tunnel {
        let records = try await persistence.records.loadRecords()
        let original = try await persistence.tunnel(for: records[TunnelRecordAccess.index(of: id, in: records)])
        let copy = Tunnel(
            name: UniqueTunnelNameResolver.uniqueName(for: original.name, takenNames: records.map(\.name)),
            configuration: original.configuration,
            routingPolicy: original.routingPolicy
        )
        try await persistence.add(copy, after: records)
        return copy
    }
}
