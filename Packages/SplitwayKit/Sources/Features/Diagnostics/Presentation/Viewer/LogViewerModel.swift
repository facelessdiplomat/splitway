import Diagnostics
import Observation
import SharedKernel

@MainActor
@Observable
public final class LogViewerModel {
    public static let refreshInterval = Duration.seconds(2)

    public private(set) var entries: [LogEntry] = []
    public private(set) var filter = LogFilter()
    public private(set) var problem: LogViewerProblem?
    public private(set) var exportedText: String?
    public private(set) var hasLoaded = false
    private var allEntries: [LogEntry] = []

    private let actions: LogViewerActions
    private let ticker: any Ticker

    public var isLogEmpty: Bool {
        allEntries.isEmpty
    }

    public var emptyState: LogViewerEmptyState? {
        guard hasLoaded, entries.isEmpty else {
            return nil
        }
        return isLogEmpty ? .noEntries : .noMatchingEntries
    }

    public init(actions: LogViewerActions, ticker: any Ticker = RepeatingTicker(interval: refreshInterval)) {
        self.actions = actions
        self.ticker = ticker
    }

    public func setMinimumLevel(_ level: LogLevel) {
        filter.minimumLevel = level
        applyFilter()
    }

    public func setSource(_ source: LogSource?) {
        filter.source = source
        applyFilter()
    }

    public func setSearchText(_ text: String) {
        filter.searchText = text
        applyFilter()
    }

    public func reload() async {
        do {
            allEntries = try await actions.loadEntries.execute()
            problem = nil
        } catch {
            allEntries = []
            problem = .unavailable
        }
        hasLoaded = true
        applyFilter()
    }

    public func followUpdates() async {
        for await _ in ticker.ticks() {
            await reload()
        }
    }

    public func clear() async {
        do {
            try await actions.clearLog.execute()
        } catch {
            problem = .unavailable
        }
        await reload()
    }

    public func prepareExport() async {
        do {
            exportedText = try await actions.exportLog.execute()
        } catch {
            problem = .unavailable
        }
    }

    public func finishExport() {
        exportedText = nil
    }

    public func dismissProblem() {
        problem = nil
    }

    private func applyFilter() {
        entries = allEntries.filter(filter.matches)
    }
}
