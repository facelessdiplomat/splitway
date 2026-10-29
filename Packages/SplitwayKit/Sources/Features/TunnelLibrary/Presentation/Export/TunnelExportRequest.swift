import TunnelLibrary

public enum TunnelExportRequest: Sendable, Equatable {
    case tunnel(TunnelIdentifier, name: String)
    case allTunnels
}
