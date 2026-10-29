public protocol LogHistory: Sendable {
    func entries() async throws(LogStoreError) -> [LogEntry]
    func removeAll() async throws(LogStoreError)
}
