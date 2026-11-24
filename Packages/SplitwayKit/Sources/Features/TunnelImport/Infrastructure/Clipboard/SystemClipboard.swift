import TunnelImport

#if canImport(UIKit)
    import Dispatch
    import UIKit
#else
    import AppKit
#endif

public struct SystemClipboard: ClipboardTextSource {
    #if canImport(UIKit)
        private static let pasteboardQueue = DispatchQueue(label: "Splitway.Pasteboard", qos: .userInitiated)
    #endif

    public init() {}

    public func text() async -> String? {
        #if canImport(UIKit)
            await withCheckedContinuation { continuation in
                Self.pasteboardQueue.async {
                    continuation.resume(returning: UIPasteboard.general.string)
                }
            }
        #else
            await MainActor.run { NSPasteboard.general.string(forType: .string) }
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
