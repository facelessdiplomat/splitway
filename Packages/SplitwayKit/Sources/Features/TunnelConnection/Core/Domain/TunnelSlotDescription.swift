import TunnelLibrary

public enum TunnelSlotDescription {
    public static func serverAddress(for tunnel: Tunnel) -> String {
        tunnel.configuration.peers.compactMap(\.endpoint).first?.description ?? tunnel.name.description
    }
}
