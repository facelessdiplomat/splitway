import TunnelConnection
import TunnelLibrary

public enum TunnelListAlert: Sendable, Equatable {
    case library(TunnelLibraryError)
    case connection(ConnectionFailure, tunnel: TunnelIdentifier)
}
