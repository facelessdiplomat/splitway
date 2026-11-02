import Diagnostics
import DiagnosticsPresentation
import DiagnosticsTestSupport
import Foundation
import SharedKernelTestSupport
import Testing

@MainActor
@Suite
struct LogViewerModelTests {
    private static let earlier = LogEntry(
        date: Date(timeIntervalSince1970: 1_793_268_900), level: .info, source: .application, message: "Tunnel saved")
    private static let later = LogEntry(
        date: Date(timeIntervalSince1970: 1_793_268_960), level: .error, source: .tunnelExtension,
        message: "Handshake failed")

    private let ticker = ManualTicker()

    @Test
    func showsTheNewestEntriesFirst() async {
        let model = viewer(InMemoryLogHistory(entries: [Self.earlier, Self.later]))

        await model.reload()

        #expect(model.entries == [Self.later, Self.earlier])
    }

    @Test
    func filtersByLevelSourceAndText() async {
        let model = viewer(InMemoryLogHistory(entries: [Self.earlier, Self.later]))
        await model.reload()

        model.setMinimumLevel(.error)
        #expect(model.entries == [Self.later])
        model.setMinimumLevel(.debug)
        model.setSource(.application)
        #expect(model.entries == [Self.earlier])
        model.setSource(nil)
        model.setSearchText("HANDSHAKE")
        #expect(model.entries == [Self.later])
    }

    @Test
    func refreshesOnEveryTickUntilClosed() async {
        let history = InMemoryLogHistory(entries: [Self.earlier])
        let model = viewer(history)
        let following = Task { await model.followUpdates() }
        await ticker.waitUntilTicking()

        ticker.tick()
        ticker.tick()
        await history.waitForReads(2)
        following.cancel()
        await following.value

        #expect(!ticker.isTicking)
    }

    @Test
    func clearsTheLog() async throws {
        let history = InMemoryLogHistory(entries: [Self.earlier, Self.later])
        let model = viewer(history)
        await model.reload()

        await model.clear()

        #expect(model.entries.isEmpty)
        #expect(try await history.entries().isEmpty)
    }

    @Test
    func exportsTheWholeLogWhateverTheFilter() async throws {
        let model = viewer(InMemoryLogHistory(entries: [Self.earlier, Self.later]))
        await model.reload()
        model.setMinimumLevel(.error)

        await model.prepareExport()

        let text = try #require(model.exportedText)
        #expect(text.contains("Tunnel saved"))
        #expect(text.contains("Handshake failed"))
        await model.finishExport(succeeded: true)
        #expect(model.exportedText == nil)
    }

    @Test
    func removesTheCopiesOfALogExportThatWasNotSaved() async throws {
        let abandonedCopies = RecordingAbandonedExportCopies()
        let model = viewer(InMemoryLogHistory(entries: [Self.earlier]), abandonedCopies: abandonedCopies)
        await model.prepareExport()
        let text = try #require(model.exportedText)

        await model.finishExport(succeeded: false)

        #expect(model.exportedText == nil)
        #expect(await abandonedCopies.removedContents == [Data(text.utf8)])
    }

    @Test
    func leavesTheCopiesOfASavedLogExportToTheSystem() async {
        let abandonedCopies = RecordingAbandonedExportCopies()
        let model = viewer(InMemoryLogHistory(entries: [Self.earlier]), abandonedCopies: abandonedCopies)
        await model.prepareExport()

        await model.finishExport(succeeded: true)

        #expect(await abandonedCopies.removedContents.isEmpty)
    }

    @Test
    func showsNoEmptyStateBeforeTheFirstLoad() {
        let model = viewer(InMemoryLogHistory())

        #expect(model.emptyState == nil)
    }

    @Test
    func tellsAnEmptyLogApartFromAFilterThatHidesEveryEntry() async {
        let emptyModel = viewer(InMemoryLogHistory())
        let filteredModel = viewer(InMemoryLogHistory(entries: [Self.earlier]))

        await emptyModel.reload()
        await filteredModel.reload()
        filteredModel.setSearchText("handshake")

        #expect(emptyModel.emptyState == .noEntries)
        #expect(emptyModel.isLogEmpty)
        #expect(filteredModel.emptyState == .noMatchingEntries)
        #expect(!filteredModel.isLogEmpty)
    }

    @Test
    func opensTheCrashReport() {
        let model = viewer(InMemoryLogHistory())
        #expect(model.crashReport == nil)

        model.showCrashReport()

        #expect(model.crashReport != nil)
    }

    @Test
    func explainsAnUnavailableLog() async {
        let model = viewer(InMemoryLogHistory(isAvailable: false))

        await model.reload()

        #expect(model.problem == .unavailable)
        #expect(model.entries.isEmpty)
    }

    private func viewer(
        _ history: InMemoryLogHistory,
        abandonedCopies: RecordingAbandonedExportCopies = RecordingAbandonedExportCopies()
    ) -> LogViewerModel {
        LogViewerModel(
            actions: LogViewerActions(
                loadEntries: LoadLogEntriesUseCase(history: history),
                clearLog: ClearLogUseCase(history: history),
                exportLog: ExportLogUseCase(history: history),
                prepareCrashReport: PrepareCrashReportUseCase(
                    logs: history,
                    reports: InMemoryDiagnosticReportHistory(),
                    archiver: StubCrashReportArchiver(),
                    clock: FixedWallClock(Self.earlier.date),
                    environment: CrashReportEnvironment(application: "Splitway", system: "iOS")
                )
            ),
            abandonedCopies: abandonedCopies,
            ticker: ticker
        )
    }
}
