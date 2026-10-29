import Foundation

public struct LogFilter: Sendable, Equatable {
    public var minimumLevel: LogLevel
    public var source: LogSource?
    public var searchText: String

    public init(minimumLevel: LogLevel = .debug, source: LogSource? = nil, searchText: String = "") {
        self.minimumLevel = minimumLevel
        self.source = source
        self.searchText = searchText
    }

    public var restrictsLevelOrSource: Bool {
        minimumLevel != .debug || source != nil
    }

    public func matches(_ entry: LogEntry) -> Bool {
        guard entry.level >= minimumLevel else { return false }
        if let source, entry.source != source {
            return false
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty || entry.message.localizedCaseInsensitiveContains(query)
    }
}
