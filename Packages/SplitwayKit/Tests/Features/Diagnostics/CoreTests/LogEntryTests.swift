import CryptoKit
import Diagnostics
import Foundation
import Testing

@Suite
struct LogEntryTests {
    private let keyText = Curve25519.KeyAgreement.PrivateKey().rawRepresentation.base64EncodedString()

    @Test
    func redactsItsMessage() {
        #expect(Self.entry(message: "loaded \(keyText)").message == "loaded [redacted]")
    }

    @Test
    func capsItsMessageLength() {
        let entry = Self.entry(message: String(repeating: "a", count: 10_000))

        #expect(entry.message.count == LogEntry.maximumMessageLength)
    }

    @Test
    func redactsBeforeCappingSoNoKeyIsCutInHalf() {
        let padding = String(repeating: "a", count: LogEntry.maximumMessageLength - 20)

        let entry = Self.entry(message: "\(padding) \(keyText)")

        #expect(!entry.message.contains(keyText.prefix(19)))
    }

    @Test
    func redactsDecodedMessages() throws {
        let encoded = try JSONEncoder().encode(Self.entry(message: "safe"))
        let tampered = try #require(String(bytes: encoded, encoding: .utf8))
            .replacingOccurrences(of: "\"safe\"", with: "\"leaked \(keyText)\"")

        let decoded = try JSONDecoder().decode(LogEntry.self, from: Data(tampered.utf8))

        #expect(decoded.message == "leaked [redacted]")
    }

    private static func entry(message: String) -> LogEntry {
        LogEntry(date: Date(timeIntervalSince1970: 0), level: .info, source: .application, message: message)
    }
}
