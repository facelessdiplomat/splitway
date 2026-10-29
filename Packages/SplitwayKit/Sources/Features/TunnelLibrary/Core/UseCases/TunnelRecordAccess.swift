struct TunnelRecordAccess: Sendable {
    let repository: any TunnelRecordRepository

    func loadRecords() async throws(TunnelLibraryError) -> [TunnelRecord] {
        do {
            return try await repository.loadRecords()
        } catch {
            throw .storage(error)
        }
    }

    func saveRecords(_ records: [TunnelRecord]) async throws(TunnelLibraryError) {
        do {
            try await repository.saveRecords(records)
        } catch {
            throw .storage(error)
        }
    }

    static func index(of tunnel: TunnelIdentifier, in records: [TunnelRecord]) throws(TunnelLibraryError) -> Int {
        guard let index = records.firstIndex(where: { record in record.id == tunnel }) else {
            throw .tunnelNotFound(tunnel)
        }
        return index
    }
}
