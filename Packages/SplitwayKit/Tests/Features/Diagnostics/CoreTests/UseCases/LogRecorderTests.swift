import Diagnostics
import Foundation
import SharedKernelTestSupport
import Synchronization
import Testing

@Suite
struct LogRecorderTests {
    private static let moment = Date(timeIntervalSince1970: 1_793_268_900)

    @Test
    func writesRedactedEntriesToTheStoreAndTheSystemLog() {
        let store = InMemoryLogStore()
        let systemLog = RecordingSystemLogWriter()
        let recorder = LogRecorder(
            source: .engine, store: store, systemLog: systemLog, clock: FixedWallClock(Self.moment))

        recorder.record(.warning, "PrivateKey = secret")

        let expected = LogEntry(date: Self.moment, level: .warning, source: .engine, message: "PrivateKey = [redacted]")
        #expect(store.storedEntries == [expected])
        #expect(systemLog.writtenEntries == [expected])
    }

    @Test
    func reportsAnUnavailableStoreToTheSystemLog() {
        let systemLog = RecordingSystemLogWriter()
        let recorder = LogRecorder(
            source: .application,
            store: InMemoryLogStore(isAvailable: false),
            systemLog: systemLog,
            clock: FixedWallClock(Self.moment)
        )

        recorder.record(.info, "tunnel started")

        #expect(systemLog.writtenEntries.map(\.message) == ["tunnel started", LogRecorder.unavailableStoreMessage])
        #expect(systemLog.writtenEntries.last?.level == .error)
    }
}

final class InMemoryLogStore: LogStore {
    private let storage = Mutex<[LogEntry]>([])
    private let isAvailable: Bool

    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
    }

    var storedEntries: [LogEntry] {
        storage.withLock { entries in entries }
    }

    func append(_ entry: LogEntry) throws(LogStoreError) {
        guard isAvailable else { throw .unavailable }
        storage.withLock { entries in entries.append(entry) }
    }

    func entries() throws(LogStoreError) -> [LogEntry] {
        storedEntries
    }

    func removeAll() throws(LogStoreError) {
        storage.withLock { entries in entries.removeAll() }
    }
}

final class RecordingSystemLogWriter: SystemLogWriter {
    private let storage = Mutex<[LogEntry]>([])

    var writtenEntries: [LogEntry] {
        storage.withLock { entries in entries }
    }

    func write(_ entry: LogEntry) {
        storage.withLock { entries in entries.append(entry) }
    }
}
