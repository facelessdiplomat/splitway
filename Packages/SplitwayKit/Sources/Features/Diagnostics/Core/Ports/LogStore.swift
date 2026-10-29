public protocol LogStore: Sendable {
    func append(_ entry: LogEntry) throws(LogStoreError)
    func entries() throws(LogStoreError) -> [LogEntry]
    func removeAll() throws(LogStoreError)
}
