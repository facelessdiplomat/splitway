import Foundation

public enum LogTextFormatter {
    public static func text(of entries: [LogEntry]) -> String {
        entries.map { entry in line(for: entry) + "\n" }.joined()
    }

    static func line(for entry: LogEntry) -> String {
        "\(entry.date.formatted(.iso8601)) \(entry.level.rawValue) \(entry.source.rawValue): \(entry.message)"
    }
}
