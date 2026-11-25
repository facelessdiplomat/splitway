import TunnelLibraryPresentation

extension AppComposition {
    static var additionMethods: [TunnelAdditionMethod] {
        #if os(iOS)
            [.importFromFile, .scanQRCode, .pasteFromClipboard, .createFromScratch]
        #else
            [.importFromFile, .pasteFromClipboard, .createFromScratch]
        #endif
    }

    func add(_ method: TunnelAdditionMethod) {
        switch method {
        case .importFromFile:
            tunnelImport.pickFiles()
        case .pasteFromClipboard:
            Task.immediate { await tunnelImport.importClipboard() }
        case .scanQRCode:
            tunnelImport.scanQRCode()
        case .createFromScratch:
            tunnelEditor.createTunnel()
        }
    }

    func paste(_ texts: [String]) {
        Task.immediate { await tunnelImport.importPastedTexts(texts) }
    }
}
