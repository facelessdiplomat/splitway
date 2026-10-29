import TunnelLibrary

public enum TunnelImportAlert: Sendable, Equatable {
    case emptyClipboard
    case library(TunnelLibraryError)
}
