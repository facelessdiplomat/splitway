import Diagnostics
import DiagnosticsInfrastructure
import Foundation
import Testing

@Suite
final class QueuedLogHistoryTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "QueuedLogHistoryTests-\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func readsAndClearsTheStoreOffTheCallingThread() async throws {
        let store = RotatingFileLogStore(directory: directory)
        let entry = LogEntry(
            date: Date(timeIntervalSince1970: 1_793_268_900), level: .info, source: .engine, message: "Up")
        try store.append(entry)
        let history = QueuedLogHistory(store: store)

        #expect(try await history.entries() == [entry])
        try await history.removeAll()
        #expect(try await history.entries().isEmpty)
    }
}
