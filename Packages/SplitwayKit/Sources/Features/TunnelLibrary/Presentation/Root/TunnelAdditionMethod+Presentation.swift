import SwiftUI

extension TunnelAdditionMethod {
    var label: Label<Text, Image> {
        Label {
            title
        } icon: {
            Image(systemName: systemImageName)
        }
    }

    var usesSystemPasteButton: Bool {
        #if os(iOS)
            self == .pasteFromClipboard
        #else
            false
        #endif
    }

    var keyboardShortcut: KeyboardShortcut? {
        switch self {
        case .importFromFile: Self.importShortcut
        case .pasteFromClipboard: KeyboardShortcut("v", modifiers: [.command, .shift])
        case .createFromScratch: KeyboardShortcut("n")
        case .scanQRCode: nil
        }
    }

    private static var importShortcut: KeyboardShortcut? {
        #if os(iOS)
            KeyboardShortcut("o", modifiers: [.command, .shift])
        #else
            KeyboardShortcut("o")
        #endif
    }

    private var title: Text {
        switch self {
        case .importFromFile: Text("Import from file", bundle: .module)
        case .pasteFromClipboard: Text("Paste from clipboard", bundle: .module)
        case .scanQRCode: Text("Scan QR code", bundle: .module)
        case .createFromScratch: Text("Create from scratch", bundle: .module)
        }
    }

    private var systemImageName: String {
        switch self {
        case .importFromFile: "doc.badge.plus"
        case .pasteFromClipboard: "doc.on.clipboard"
        case .scanQRCode: "qrcode.viewfinder"
        case .createFromScratch: "square.and.pencil"
        }
    }
}
