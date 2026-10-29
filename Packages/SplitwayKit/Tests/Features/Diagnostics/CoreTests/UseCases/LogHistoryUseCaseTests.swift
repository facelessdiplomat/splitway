import Diagnostics
import DiagnosticsTestSupport
import Foundation
import Testing

@Suite
struct LogHistoryUseCaseTests {
    private static let earlier = LogEntry(
        date: Date(timeIntervalSince1970: 1_793_268_900), level: .info, source: .application, message: "Started")
    private static let later = LogEntry(
        date: Date(timeIntervalSince1970: 1_793_268_960), level: .error, source: .tunnelExtension, message: "Stopped")

    @Test
    func loadsTheNewestEntriesFirst() async throws {
        let history = InMemoryLogHistory(entries: [Self.earlier, Self.later])

        let entries = try await LoadLogEntriesUseCase(history: history).execute()

        #expect(entries == [Self.later, Self.earlier])
    }

    @Test
    func exportsTheWholeLogAsTextInTheOrderItWasWritten() async throws {
        let history = InMemoryLogHistory(entries: [Self.earlier, Self.later])

        let text = try await ExportLogUseCase(history: history).execute()

        #expect(
            text == """
                2026-10-29T10:15:00Z info application: Started
                2026-10-29T10:16:00Z error tunnel-extension: Stopped

                """
        )
    }

    @Test
    func clearsTheLog() async throws {
        let history = InMemoryLogHistory(entries: [Self.earlier])

        try await ClearLogUseCase(history: history).execute()

        #expect(try await history.entries().isEmpty)
    }
}
