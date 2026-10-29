import Diagnostics

public struct LogViewerActions: Sendable {
    let loadEntries: LoadLogEntriesUseCase
    let clearLog: ClearLogUseCase
    let exportLog: ExportLogUseCase

    public init(loadEntries: LoadLogEntriesUseCase, clearLog: ClearLogUseCase, exportLog: ExportLogUseCase) {
        self.loadEntries = loadEntries
        self.clearLog = clearLog
        self.exportLog = exportLog
    }
}
