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

    private let actions: TunnelImportActions
    private let didImport: @MainActor () async -> Void

    public static var pastedTunnelName: TunnelName {
        (try? TunnelName(String(localized: "Pasted tunnel", bundle: .module))) ?? .untitled
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

    public func dismissAlert() {
        alert = nil
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
