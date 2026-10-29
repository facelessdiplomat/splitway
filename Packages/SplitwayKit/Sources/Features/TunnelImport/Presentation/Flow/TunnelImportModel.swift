import Foundation
import Observation
import TunnelImport
import TunnelLibrary

@MainActor
@Observable
public final class TunnelImportModel {
    public var preview: ImportPreviewModel?
    public var isPickingFiles = false
    public private(set) var alert: TunnelImportAlert?
    public var qrScanner: QRScannerModel?
    private var scannedTexts: [String] = []

    private let actions: TunnelImportActions
    private let didImport: @MainActor () async -> Void

    public static var fallbackNames: ImportFallbackNames {
        ImportFallbackNames(
            pastedText: (try? TunnelName(String(localized: "Pasted tunnel", bundle: .module))) ?? .untitled,
            scannedCode: (try? TunnelName(String(localized: "Scanned tunnel", bundle: .module))) ?? .untitled
        )
    }

    public init(actions: TunnelImportActions, didImport: @escaping @MainActor () async -> Void) {
        self.actions = actions
        self.didImport = didImport
    }

    public func pickFiles() {
        isPickingFiles = true
    }

    public func importFiles(_ files: [URL]) async {
        let batch = await actions.fileReader.read(files)
        await showPreview(of: batch.payloads, unreadableFileNames: batch.unreadableFileNames)
    }

    public func importClipboard() async {
        guard let text = await actions.clipboard.text(), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            alert = .emptyClipboard
            return
        }
        await showPreview(of: [.text(text)])
    }

    public func importDropped(_ payloads: [ImportPayload]) async {
        await showPreview(of: payloads)
    }

    public func scanQRCode() {
        qrScanner = QRScannerModel(
            cameraAccess: actions.cameraAccess,
            decoder: actions.qrCodeDecoder
        ) { [weak self] texts in
            self?.finishScanning(with: texts)
        }
    }

    public func previewScannedCodes() async {
        let texts = scannedTexts
        scannedTexts = []
        guard !texts.isEmpty else { return }
        await showPreview(of: texts.map(ImportPayload.qrCode))
    }

    public func dismissAlert() {
        alert = nil
    }

    private func finishScanning(with texts: [String]) {
        scannedTexts = texts
        qrScanner = nil
    }

    private func showPreview(of payloads: [ImportPayload], unreadableFileNames: [String] = []) async {
        do {
            let prepared = try await actions.prepareImport.execute(payloads, unreadableFileNames: unreadableFileNames)
            preview = ImportPreviewModel(preview: prepared, confirmImport: actions.confirmImport, didImport: didImport)
        } catch {
            alert = .library(error)
        }
    }
}
