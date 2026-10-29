public protocol SystemLogWriter: Sendable {
    func write(_ entry: LogEntry)
}
