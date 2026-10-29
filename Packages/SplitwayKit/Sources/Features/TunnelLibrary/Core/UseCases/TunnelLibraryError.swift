public enum TunnelLibraryError: Error, Equatable, Sendable {
    case storage(TunnelStorageError)
    case tunnelNotFound(TunnelIdentifier)
    case unreadableConfiguration(TunnelIdentifier)
    case activeTunnelCouldNotBeStopped
    case orderDoesNotMatchTunnels
    case archiveFailed
}
