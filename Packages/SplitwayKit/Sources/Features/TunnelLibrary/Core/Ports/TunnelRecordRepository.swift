public protocol TunnelRecordRepository: Sendable {
    func loadRecords() async throws(TunnelStorageError) -> [TunnelRecord]
    func saveRecords(_ records: [TunnelRecord]) async throws(TunnelStorageError)
}
