import Foundation
import Testing
import TunnelConfigurationTestSupport
import TunnelImport
import TunnelImportPresentation

@MainActor
@Suite
struct TunnelImportModelTests {
    private static let officeAndHome = NamedImportFileReader(
        contentsByName: ["Office.conf": WgQuickFixtures.minimal, "Home.conf": WgQuickFixtures.full]
    )

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
    func addsFilesOpenedWhileThePreviewIsOpen() async throws {
        let model = try ImportTestFlow().model(fileReader: Self.officeAndHome)

        await model.importFiles([URL(filePath: "/Office.conf")])
        await model.importFiles([URL(filePath: "/Home.conf")])

        #expect(model.preview?.rows.map(\.name) == ["Office", "Home"])
    }

    @Test
    func collectsFilesOpenedTogetherIntoOnePreview() async throws {
        let model = try ImportTestFlow().model(fileReader: Self.officeAndHome)

        await withTaskGroup(of: Void.self) { group in
            for name in ["Office.conf", "Home.conf"] {
                group.addTask { await model.importFiles([URL(filePath: "/" + name)]) }
            }
        }

        #expect(Set(model.preview?.rows.map(\.name) ?? []) == ["Office", "Home"])
    }

    @Test
    func startsANewPreviewAfterTheOpenOneWasImported() async throws {
        let model = try ImportTestFlow().model(fileReader: Self.officeAndHome)
        await model.importFiles([URL(filePath: "/Office.conf")])
        await model.preview?.confirm()

        await model.importFiles([URL(filePath: "/Home.conf")])

        #expect(model.preview?.rows.map(\.name) == ["Home"])
    }

    @Test
    func startsANewPreviewAfterTheOpenOneWasDismissed() async throws {
        let model = try ImportTestFlow().model(fileReader: Self.officeAndHome)
        await model.importFiles([URL(filePath: "/Office.conf")])
        model.preview = nil

        await model.importFiles([URL(filePath: "/Home.conf")])

        #expect(model.preview?.rows.map(\.name) == ["Home"])
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
