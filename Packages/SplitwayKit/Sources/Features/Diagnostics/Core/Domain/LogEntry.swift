import Foundation

public struct LogEntry: Sendable, Hashable {
    public static let maximumMessageLength = 4096

    public let date: Date
    public let level: LogLevel
    public let source: LogSource
    public let message: String

    public init(date: Date, level: LogLevel, source: LogSource, message: String) {
        self.date = date
        self.level = level
        self.source = source
        self.message = String(LogRedactor.redact(message).prefix(Self.maximumMessageLength))
    }
}
