import Diagnostics

public struct LogViewerActions: Sendable {
    let loadEntries: LoadLogEntriesUseCase
    let clearLog: ClearLogUseCase
    let exportLog: ExportLogUseCase
    let prepareCrashReport: PrepareCrashReportUseCase

    public init(
        loadEntries: LoadLogEntriesUseCase,
        clearLog: ClearLogUseCase,
        exportLog: ExportLogUseCase,
        prepareCrashReport: PrepareCrashReportUseCase
    ) {
        self.loadEntries = loadEntries
        self.clearLog = clearLog
        self.exportLog = exportLog
        self.prepareCrashReport = prepareCrashReport
    }
}
