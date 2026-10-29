import SharedKernel

public struct LogRecorder: Sendable {
    public static let unavailableStoreMessage = "Diagnostic log store is unavailable"

    private let source: LogSource
    private let store: any LogStore
    private let systemLog: any SystemLogWriter
    private let clock: any WallClock

    public init(
        source: LogSource,
        store: any LogStore,
        systemLog: any SystemLogWriter,
        clock: any WallClock = SystemWallClock()
    ) {
        self.source = source
        self.store = store
        self.systemLog = systemLog
        self.clock = clock
    }

    public func record(_ level: LogLevel, _ message: String) {
        let entry = LogEntry(date: clock.now(), level: level, source: source, message: message)
        systemLog.write(entry)
        do {
            try store.append(entry)
        } catch {
            systemLog.write(
                LogEntry(date: entry.date, level: .error, source: source, message: Self.unavailableStoreMessage))
        }
    }
}
