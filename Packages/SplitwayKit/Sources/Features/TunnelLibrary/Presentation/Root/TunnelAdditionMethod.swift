public enum TunnelAdditionMethod: Sendable, Hashable, CaseIterable {
    case importFromFile
    case pasteFromClipboard
    case scanQRCode
    case createFromScratch
}
