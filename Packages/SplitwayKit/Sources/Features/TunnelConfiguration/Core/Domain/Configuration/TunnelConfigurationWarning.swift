public enum TunnelConfigurationWarning: Sendable, Hashable {
    case noPeers
    case interfaceWithoutAddresses
    case peerUsesInterfacePublicKey(PublicKey)
    case peerWithoutAllowedIPs(PublicKey)
}
