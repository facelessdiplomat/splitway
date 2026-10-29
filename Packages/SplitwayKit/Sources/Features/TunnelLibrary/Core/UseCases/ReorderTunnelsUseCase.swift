public struct ReorderTunnelsUseCase: Sendable {
    private let records: TunnelRecordAccess

    public init(records: any TunnelRecordRepository) {
        self.records = TunnelRecordAccess(repository: records)
    }

    public func execute(order: [TunnelIdentifier]) async throws(TunnelLibraryError) {
        let storedRecords = try await records.loadRecords()
        let recordsByIdentifier = Dictionary(
            storedRecords.map { record in (record.id, record) },
            uniquingKeysWith: { first, _ in first }
        )
        guard order.count == storedRecords.count, Set(order) == Set(recordsByIdentifier.keys) else {
            throw .orderDoesNotMatchTunnels
        }
        try await records.saveRecords(order.compactMap { identifier in recordsByIdentifier[identifier] })
    }
}
