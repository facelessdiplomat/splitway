import Diagnostics
import DiagnosticsTestSupport
import Foundation
import SharedKernelTestSupport
import Testing

@Suite
struct PrepareCrashReportUseCaseTests {
    private static let moment = Date(timeIntervalSince1970: 1_793_268_900)
    private static let environment = CrashReportEnvironment(application: "Splitway 0.1.0 (1)", system: "iOS 26.0")

    @Test
    func archivesTheLogAndTheReportsCreatedNow() async throws {
        let logs = InMemoryLogHistory(entries: [
            LogEntry(date: Self.moment, level: .info, source: .application, message: "Started")
        ])
        let reports = InMemoryDiagnosticReportHistory(reports: [
            DiagnosticReport(kind: .crash, date: Self.moment, payload: "{}")
        ])

        let prepared = try await useCase(logs: logs, reports: reports).execute()

        #expect(prepared.bundle.files.map(\.name) == ["info.txt", "crash-2026-10-29T10-15-00Z.json", "log.txt"])
        #expect(prepared.archive == Data("info.txt crash-2026-10-29T10-15-00Z.json log.txt".utf8))
        let infoFile = try #require(prepared.bundle.files.first)
        let info = try #require(String(bytes: infoFile.contents, encoding: .utf8))
        #expect(info.contains("2026-10-29T10:15:00Z"))
    }

    @Test
    func explainsAnUnreadableHistory() async {
        let unreadableLog = useCase(logs: InMemoryLogHistory(isAvailable: false), reports: .init())
        let unreadableReports = useCase(logs: InMemoryLogHistory(), reports: .init(isAvailable: false))

        await #expect(throws: CrashReportError.historyUnavailable) { try await unreadableLog.execute() }
        await #expect(throws: CrashReportError.historyUnavailable) { try await unreadableReports.execute() }
    }

    @Test
    func explainsAnArchiveThatCouldNotBeWritten() async {
        let failing = useCase(
            logs: InMemoryLogHistory(), reports: .init(), archiver: StubCrashReportArchiver(fails: true))

        await #expect(throws: CrashReportError.archiveFailed) { try await failing.execute() }
    }

    private func useCase(
        logs: InMemoryLogHistory,
        reports: InMemoryDiagnosticReportHistory,
        archiver: StubCrashReportArchiver = StubCrashReportArchiver()
    ) -> PrepareCrashReportUseCase {
        PrepareCrashReportUseCase(
            logs: logs,
            reports: reports,
            archiver: archiver,
            clock: FixedWallClock(Self.moment),
            environment: Self.environment
        )
    }
}
