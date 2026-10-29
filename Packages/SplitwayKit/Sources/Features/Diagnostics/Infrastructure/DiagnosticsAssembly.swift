import Diagnostics
import Foundation
import SharedKernel

public struct DiagnosticsAssembly: Sendable {
    private static let reportsDirectoryName = "Reports"

    private let store: RotatingFileLogStore
    private let reportStore: FileDiagnosticReportStore
    private let subsystem: String

    public init(logDirectory: URL, subsystem: String) {
        store = RotatingFileLogStore(directory: logDirectory)
        reportStore = FileDiagnosticReportStore(directory: logDirectory.appending(path: Self.reportsDirectoryName))
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

    #if canImport(MetricKit)
        public var reportCollector: MetricKitReportCollector {
            MetricKitReportCollector(store: reportStore)
        }
    #endif

    public func prepareCrashReport(environment: CrashReportEnvironment) -> PrepareCrashReportUseCase {
        PrepareCrashReportUseCase(
            logs: QueuedLogHistory(store: store),
            reports: reportStore,
            archiver: ZIPCrashReportArchiver(),
            clock: SystemWallClock(),
            environment: environment
        )
    }

    public func recorder(for source: LogSource, category: String) -> LogRecorder {
        LogRecorder(source: source, store: store, systemLog: OSLogWriter(subsystem: subsystem, category: category))
    }
}
