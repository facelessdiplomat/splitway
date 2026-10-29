import Diagnostics
import Foundation

public struct DiagnosticsAssembly: Sendable {
    private let store: RotatingFileLogStore
    private let subsystem: String

    public init(logDirectory: URL, subsystem: String) {
        store = RotatingFileLogStore(directory: logDirectory)
        self.subsystem = subsystem
    }

    public var loadLogEntries: LoadLogEntriesUseCase {
        LoadLogEntriesUseCase(history: QueuedLogHistory(store: store))
    }

    public var clearLog: ClearLogUseCase {
        ClearLogUseCase(history: QueuedLogHistory(store: store))
    }

    public var exportLog: ExportLogUseCase {
        ExportLogUseCase(history: QueuedLogHistory(store: store))
    }

    public func recorder(for source: LogSource, category: String) -> LogRecorder {
        LogRecorder(source: source, store: store, systemLog: OSLogWriter(subsystem: subsystem, category: category))
    }
}
