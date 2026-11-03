import AppKit
import TunnelImport

public struct SystemClipboard: ClipboardTextSource {

    public init() {}

    public func text() async -> String? {
        await MainActor.run { NSPasteboard.general.string(forType: .string) }
    }

    @MainActor
    public func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
