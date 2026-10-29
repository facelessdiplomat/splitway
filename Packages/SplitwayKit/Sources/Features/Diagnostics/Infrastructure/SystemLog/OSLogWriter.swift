import Diagnostics
import os

public struct OSLogWriter: SystemLogWriter {
    private let logger: Logger

    public init(subsystem: String, category: String) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func write(_ entry: LogEntry) {
        logger.log(level: Self.osLogType(of: entry.level), "\(entry.message, privacy: .public)")
    }

    private static func osLogType(of level: LogLevel) -> OSLogType {
        switch level {
        case .debug: .debug
        case .info: .info
        case .warning: .default
        case .error: .error
        }
    }
}
