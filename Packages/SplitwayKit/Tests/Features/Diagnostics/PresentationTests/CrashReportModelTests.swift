import Diagnostics
import DiagnosticsPresentation
import DiagnosticsTestSupport
import Foundation
import SharedKernelTestSupport
import Testing

@MainActor
@Suite
struct CrashReportModelTests {
    private static let moment = Date(timeIntervalSince1970: 1_793_268_900)

    @Test
    func listsTheArchiveContentsOncePrepared() async {
        let model = report(
            logs: InMemoryLogHistory(entries: [
                LogEntry(date: Self.moment, level: .info, source: .application, message: "Started")
            ]))
        #expect(model.state == .preparing)

        await model.prepare()

        guard case .ready(let prepared) = model.state else {
            Issue.record("The report is not ready: \(model.state)")
            return
        }
        #expect(prepared.bundle.files.map(\.name) == ["info.txt", "log.txt"])
        #expect(prepared.archive == Data("info.txt log.txt".utf8))
    }

    @Test
    func explainsAReportThatCouldNotBePrepared() async {
        let model = report(logs: InMemoryLogHistory(isAvailable: false))

        await model.prepare()

        #expect(model.state == .unavailable)
    }

    private func report(logs: InMemoryLogHistory) -> CrashReportModel {
        CrashReportModel(
            prepareReport: PrepareCrashReportUseCase(
                logs: logs,
                reports: InMemoryDiagnosticReportHistory(),
                archiver: StubCrashReportArchiver(),
                clock: FixedWallClock(Self.moment),
                environment: CrashReportEnvironment(application: "Splitway 0.1.0 (1)", system: "iOS 26.0")
            )
        )
    }
}
