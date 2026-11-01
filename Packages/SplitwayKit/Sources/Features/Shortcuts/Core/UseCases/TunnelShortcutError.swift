import TunnelConnection

public enum TunnelShortcutError: Error, Sendable, Equatable {
    case libraryUnavailable
    case tunnelNotFound
    case tunnelUnreadable
    case connectionFailed(ConnectionFailure)
    case disconnectionFailed
}
