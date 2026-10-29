import Diagnostics
import DiagnosticsInfrastructure
import Foundation
import Testing

@Suite
final class RotatingFileLogStoreTests {
    private static let firstMoment = Date(timeIntervalSince1970: 1_793_268_900)

    private let directory = FileManager.default.temporaryDirectory.appending(path: "splitway-log-\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func startsEmpty() throws {
        #expect(try RotatingFileLogStore(directory: directory).entries().isEmpty)
    }

    @Test
    func returnsEntriesInTheOrderTheyWereWritten() throws {
        let store = RotatingFileLogStore(directory: directory)
        let entries = (1...3).map(Self.entry)

        for entry in entries {
            try store.append(entry)
        }

        #expect(try RotatingFileLogStore(directory: directory).entries() == entries)
    }

    @Test
    func keepsOnlyTheNewestEntriesWithinItsCapacity() throws {
        let store = RotatingFileLogStore(directory: directory, capacity: 4096)

        for number in 1...200 {
            try store.append(Self.entry(number))
        }

        let numbers = try store.entries().map(Self.number)
        #expect(numbers.last == 200)
        #expect(numbers.first.map { first in first > 1 } == true)
        #expect(numbers == Array(try #require(numbers.first)...200))
        #expect(try storedByteCount() <= 4096)
    }

    @Test
    func keepsEveryEntryOfConcurrentWriters() async throws {
        let firstWriter = RotatingFileLogStore(directory: directory)
        let secondWriter = RotatingFileLogStore(directory: directory)

        await withTaskGroup { group in
            for number in 1...400 {
                let writer = number.isMultiple(of: 2) ? firstWriter : secondWriter
                group.addTask { _ = try? writer.append(Self.entry(number)) }
            }
        }

        let numbers = try firstWriter.entries().map(Self.number)
        #expect(numbers.count == 400)
        #expect(Set(numbers) == Set(1...400))
    }

    @Test
    func skipsLinesThatCannotBeDecoded() throws {
        let store = RotatingFileLogStore(directory: directory)
        try store.append(Self.entry(1))
        let handle = try FileHandle(forWritingTo: directory.appending(path: "diagnostics.log"))
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("{\"broken\n".utf8))
        try handle.close()

        try store.append(Self.entry(2))

        #expect(try store.entries() == [Self.entry(1), Self.entry(2)])
    }

    @Test
    func removesEveryEntry() throws {
        let store = RotatingFileLogStore(directory: directory, capacity: 4096)
        for number in 1...100 {
            try store.append(Self.entry(number))
        }

        try store.removeAll()

        #expect(try store.entries().isEmpty)
    }

    private func storedByteCount() throws -> Int {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
            .filter { url in url.pathExtension == "log" }
            .reduce(0) { total, url in total + (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) }
    }

    private static func entry(_ number: Int) -> LogEntry {
        LogEntry(
            date: firstMoment.addingTimeInterval(TimeInterval(number)),
            level: .info,
            source: .tunnelExtension,
            message: "entry \(number)"
        )
    }

    private static func number(of entry: LogEntry) -> Int {
        Int(entry.message.dropFirst("entry ".count)) ?? 0
    }
}
