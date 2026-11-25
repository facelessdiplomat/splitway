import Foundation
import Testing
import TunnelConfigurationTestSupport
import TunnelImport
import TunnelImportPresentation

@MainActor
@Suite
struct TunnelImportModelTests {
    @Test
    func previewsPickedFiles() async throws {
        let files = ImportFileBatch(
            payloads: [.file(name: "Office.conf", contents: Data(WgQuickFixtures.minimal.utf8))],
            unreadableFileNames: ["Locked.conf"]
        )
        let model = try ImportTestFlow().model(files: files)

        await model.importFiles([URL(filePath: "/Office.conf"), URL(filePath: "/Locked.conf")])

        #expect(model.preview?.rows.map(\.name) == ["Office"])
        #expect(
            model.preview?.failures == [ImportSourceFailure(source: .file(name: "Locked.conf"), reason: .unreadable)]
        )
    }

    @Test
    func previewsTheClipboard() async throws {
        let model = try ImportTestFlow().model(clipboard: WgQuickFixtures.minimal)

        await model.importClipboard()

        #expect(model.preview?.rows.map(\.name) == [ImportTestFlow.pastedName])
    }

    @Test
    func explainsThatTheClipboardHasNothingToImport() async throws {
        let model = try ImportTestFlow().model(clipboard: "  \n")

        await model.importClipboard()

        #expect(model.preview == nil)
        #expect(model.alert == .emptyClipboard)
    }

    @Test
    func previewsPastedText() async throws {
        let model = try ImportTestFlow().model()

        await model.importPastedTexts([WgQuickFixtures.minimal])

        #expect(model.preview?.rows.map(\.name) == [ImportTestFlow.pastedName])
    }

    @Test
    func skipsBlankPastedItems() async throws {
        let model = try ImportTestFlow().model()

        await model.importPastedTexts([" \n", WgQuickFixtures.minimal])

        #expect(model.preview?.rows.map(\.name) == [ImportTestFlow.pastedName])
        #expect(model.preview?.failures.isEmpty == true)
    }

    @Test(arguments: [[], ["", "  \n"]])
    func explainsThatNothingWasPasted(texts: [String]) async throws {
        let model = try ImportTestFlow().model()

        await model.importPastedTexts(texts)

        #expect(model.preview == nil)
        #expect(model.alert == .emptyClipboard)
    }

    @Test
    func previewsAScannedCodeOnceTheScannerHasClosed() async throws {
        let model = try ImportTestFlow().model()
        model.scanQRCode()
        let scanner = try #require(model.qrScanner)
        await scanner.prepare(isCameraScanningSupported: true)

        scanner.recognize(WgQuickFixtures.minimal)

        #expect(model.qrScanner == nil)
        #expect(model.preview == nil)
        await model.previewScannedCodes()
        #expect(model.preview?.rows.map(\.name) == [ImportTestFlow.scannedName])
    }

    @Test
    func showsNothingWhenTheScannerClosesWithoutACode() async throws {
        let model = try ImportTestFlow().model()
        model.scanQRCode()

        model.qrScanner = nil
        await model.previewScannedCodes()

        #expect(model.preview == nil)
    }

    @Test
    func previewsDroppedFiles() async throws {
        let model = try ImportTestFlow().model()

        await model.importDropped([.file(name: "Home.conf", contents: Data(WgQuickFixtures.full.utf8))])

        #expect(model.preview?.rows.map(\.name) == ["Home"])
    }

    @Test
    func asksForFilesToImport() throws {
        let model = try ImportTestFlow().model()

        model.pickFiles()

        #expect(model.isPickingFiles)
    }
}
