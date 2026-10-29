import Foundation

extension LogEntry: Codable {
    private enum CodingKeys: String, CodingKey {
        case date
        case level
        case source
        case message
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            date: try container.decode(Date.self, forKey: .date),
            level: try container.decode(LogLevel.self, forKey: .level),
            source: try container.decode(LogSource.self, forKey: .source),
            message: try container.decode(String.self, forKey: .message)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(level, forKey: .level)
        try container.encode(source, forKey: .source)
        try container.encode(message, forKey: .message)
    }
}
