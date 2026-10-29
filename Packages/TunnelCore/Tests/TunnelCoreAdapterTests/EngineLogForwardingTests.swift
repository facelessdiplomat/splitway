import Diagnostics
import Synchronization
import Testing
import TunnelCoreFramework

@testable import TunnelCoreAdapter

@Suite
struct EngineLogForwardingTests {
    @Test
    func storesEngineLinesWithTheirKeysMasked() throws {
        let store = RecordingLogStore()
        let destination = EngineLogDestination(
            recorder: LogRecorder(source: .engine, store: store, systemLog: DiscardingSystemLogWriter())
        )
        let privateKeyHex = String(repeating: "ab", count: 32)

        destination.forward(level: .verbose, message: "UAPI set: private_key=\(privateKeyHex)")

        let entry = try #require(store.storedEntries.first)
        #expect(entry.message == "UAPI set: private_key=[redacted]")
        #expect(entry.level == .debug)
        #expect(entry.source == .engine)
    }

    @Test
    func storesEngineErrorsAsErrors() throws {
        let store = RecordingLogStore()
        let destination = EngineLogDestination(
            recorder: LogRecorder(source: .engine, store: store, systemLog: DiscardingSystemLogWriter())
        )

        destination.forward(level: .error, message: "Failed to send handshake initiation")

        #expect(store.storedEntries.map(\.level) == [.error])
    }
}

final class RecordingLogStore: LogStore {
    private let storage = Mutex<[LogEntry]>([])

    var storedEntries: [LogEntry] {
        storage.withLock { entries in entries }
    }

    func append(_ entry: LogEntry) throws(LogStoreError) {
        storage.withLock { entries in entries.append(entry) }
    }

    func entries() throws(LogStoreError) -> [LogEntry] {
        storedEntries
    }

    func removeAll() throws(LogStoreError) {
        storage.withLock { entries in entries.removeAll() }
    }
}

struct DiscardingSystemLogWriter: SystemLogWriter {
    func write(_ entry: LogEntry) {}
}
