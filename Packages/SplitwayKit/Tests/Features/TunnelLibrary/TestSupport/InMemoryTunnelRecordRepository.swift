import TunnelLibrary

public actor InMemoryTunnelRecordRepository: TunnelRecordRepository {
    public private(set) var records: [TunnelRecord]
    private var remainingSuccessfulSaves: Int?

    public init(records: [TunnelRecord] = []) {
        self.records = records
    }

    public func failSaves(afterSuccessfulSaves successfulSaveCount: Int) {
        remainingSuccessfulSaves = successfulSaveCount
    }

    public func loadRecords() async throws(TunnelStorageError) -> [TunnelRecord] {
        records
    }

    public func saveRecords(_ records: [TunnelRecord]) async throws(TunnelStorageError) {
        if let remainingSuccessfulSaves {
            guard remainingSuccessfulSaves > 0 else { throw .unavailable }
            self.remainingSuccessfulSaves = remainingSuccessfulSaves - 1
        }
        self.records = records
    }
}
