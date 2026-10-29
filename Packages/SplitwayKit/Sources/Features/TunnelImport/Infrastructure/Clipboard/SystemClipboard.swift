import TunnelImport

#if canImport(UIKit)
    import UIKit
#else
    import AppKit
#endif

public struct SystemClipboard: ClipboardTextSource {
    public init() {}

    @MainActor
    public func text() async -> String? {
        #if canImport(UIKit)
            return UIPasteboard.general.string
        #else
            return NSPasteboard.general.string(forType: .string)
        #endif
    }

    @MainActor
    public func copy(_ text: String) {
        #if canImport(UIKit)
            UIPasteboard.general.string = text
        #else
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}
