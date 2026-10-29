import TunnelConnection
import TunnelLibrary

public enum TunnelEditorFailure: Error, Sendable, Equatable {
    case saving(TunnelLibraryError)
    case restarting(ConnectionFailure)
}
