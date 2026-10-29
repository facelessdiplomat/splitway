public struct RenameTunnelUseCase: Sendable {
    private let records: TunnelRecordAccess

    public init(records: any TunnelRecordRepository) {
        self.records = TunnelRecordAccess(repository: records)
    }

    public func execute(id: TunnelIdentifier, to proposedName: TunnelName) async throws(TunnelLibraryError)
        -> TunnelName
    {
        var storedRecords = try await records.loadRecords()
        let index = try TunnelRecordAccess.index(of: id, in: storedRecords)
        let otherNames = storedRecords.indices.filter { $0 != index }.map { storedRecords[$0].name }
        let name = UniqueTunnelNameResolver.uniqueName(for: proposedName, takenNames: otherNames)
        storedRecords[index] = TunnelRecord(id: id, name: name, routingPolicy: storedRecords[index].routingPolicy)
        try await records.saveRecords(storedRecords)
        return name
    }
}
