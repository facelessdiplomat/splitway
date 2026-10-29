import Diagnostics
import DiagnosticsInfrastructure
import Foundation
import Testing

@Suite
final class FileDiagnosticReportStoreTests {
    private static let moment = Date(timeIntervalSince1970: 1_793_268_900)

    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "FileDiagnosticReportStoreTests-\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func startsWithoutReports() async throws {
        #expect(try await FileDiagnosticReportStore(directory: directory).reports().isEmpty)
    }

    @Test
    func readsBackTheSavedReportsOldestFirst() async throws {
        let store = FileDiagnosticReportStore(directory: directory)
        let newer = DiagnosticReport(kind: .hang, date: Self.moment.addingTimeInterval(60), payload: "{\"hang\":1}")
        let older = DiagnosticReport(kind: .crash, date: Self.moment, payload: "{\"crash\":1}")

        try store.save([newer, older])

        #expect(try await FileDiagnosticReportStore(directory: directory).reports() == [older, newer])
    }

    @Test
    func keepsOnlyTheNewestReports() async throws {
        let store = FileDiagnosticReportStore(directory: directory)
        let reports = (0..<(FileDiagnosticReportStore.maximumReportCount + 5)).map { index in
            DiagnosticReport(kind: .crash, date: Self.moment.addingTimeInterval(Double(index)), payload: "\(index)")
        }

        try store.save(reports)

        let kept = try await store.reports()
        #expect(kept.count == FileDiagnosticReportStore.maximumReportCount)
        #expect(kept.first?.payload == "5")
        #expect(kept.last?.payload == "\(FileDiagnosticReportStore.maximumReportCount + 4)")
    }
}
