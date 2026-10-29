extension TunnelConfiguration {
    public var warnings: [TunnelConfigurationWarning] {
        interfaceWarnings + peers.flatMap(warnings(for:))
    }

    private var interfaceWarnings: [TunnelConfigurationWarning] {
        var warnings: [TunnelConfigurationWarning] = []
        if peers.isEmpty {
            warnings.append(.noPeers)
        }
        if interface.addresses.isEmpty {
            warnings.append(.interfaceWithoutAddresses)
        }
        return warnings
    }

    private func warnings(for peer: PeerConfiguration) -> [TunnelConfigurationWarning] {
        var warnings: [TunnelConfigurationWarning] = []
        if peer.publicKey == interface.privateKey.publicKey {
            warnings.append(.peerUsesInterfacePublicKey(peer.publicKey))
        }
        if peer.allowedIPs.isEmpty {
            warnings.append(.peerWithoutAllowedIPs(peer.publicKey))
        }
        return warnings
    }
}
