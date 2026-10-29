import SharedKernel

public struct PrepareCrashReportUseCase: Sendable {
    private let logs: any LogHistory
    private let reports: any DiagnosticReportHistory
    private let archiver: any CrashReportArchiver
    private let clock: any WallClock
    private let environment: CrashReportEnvironment
    private let builder = CrashReportBundleBuilder()

    public init(
        logs: any LogHistory,
        reports: any DiagnosticReportHistory,
        archiver: any CrashReportArchiver,
        clock: any WallClock,
        environment: CrashReportEnvironment
    ) {
        self.logs = logs
        self.reports = reports
        self.archiver = archiver
        self.clock = clock
        self.environment = environment
    }

    public func execute() async throws(CrashReportError) -> PreparedCrashReport {
        let logEntries: [LogEntry]
        let diagnosticReports: [DiagnosticReport]
        do {
            logEntries = try await logs.entries()
            diagnosticReports = try await reports.reports()
        } catch {
            throw .historyUnavailable
        }
        let info = CrashReportInfo(
            application: environment.application, system: environment.system, createdAt: clock.now())
        let bundle = builder.bundle(info: info, logEntries: logEntries, reports: diagnosticReports)
        do {
            return PreparedCrashReport(bundle: bundle, archive: try archiver.archive(bundle))
        } catch {
            throw .archiveFailed
        }
    }
}
