import Diagnostics
import Foundation

struct LogLineCoder: Sendable {
    private static let lineSeparator = UInt8(ascii: "\n")
    private static let timestampStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(Self.timestampStyle))
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            try Self.timestampStyle.parse(decoder.singleValueContainer().decode(String.self))
        }
        self.encoder = encoder
        self.decoder = decoder
    }

    func line(for entry: LogEntry) throws(LogStoreError) -> Data {
        do {
            return try encoder.encode(entry) + [Self.lineSeparator]
        } catch {
            throw .unavailable
        }
    }

    func entries(in segment: Data) -> [LogEntry] {
        segment.split(separator: Self.lineSeparator).compactMap { line in
            try? decoder.decode(LogEntry.self, from: line)
        }
    }
}
