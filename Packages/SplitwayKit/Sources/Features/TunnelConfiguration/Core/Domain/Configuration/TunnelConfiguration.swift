public struct TunnelConfiguration: Sendable, Hashable {
    public let interface: InterfaceConfiguration
    public let peers: [PeerConfiguration]

    public init(interface: InterfaceConfiguration, peers: [PeerConfiguration]) throws(TunnelConfigurationError) {
        var seenPublicKeys: Set<PublicKey> = []
        for peer in peers where !seenPublicKeys.insert(peer.publicKey).inserted {
            throw .duplicatePeerPublicKey(peer.publicKey)
        }
        self.interface = interface
        self.peers = peers
    }
}
