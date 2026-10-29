import SharedKernel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct TunnelConfigurationTests {
    @Test
    func acceptsAConfigurationWithUniquePeersAndReportsNoWarnings() throws {
        let configuration = try TunnelConfiguration(
            interface: interface(addresses: ["10.14.0.2/16"]),
            peers: [peer(SampleKeys.firstPeerPublicKey(), allowing: ["0.0.0.0/0"])]
        )

        #expect(configuration.peers.count == 1)
        #expect(configuration.warnings.isEmpty)
    }

    @Test
    func rejectsPeersThatShareAPublicKey() throws {
        let duplicatedKey = try SampleKeys.firstPeerPublicKey()
        let interface = try interface(addresses: ["10.14.0.2/16"])
        let peers = try [peer(duplicatedKey, allowing: ["10.0.0.0/8"]), peer(duplicatedKey, allowing: ["10.1.0.0/16"])]

        #expect(throws: TunnelConfigurationError.duplicatePeerPublicKey(duplicatedKey)) {
            try TunnelConfiguration(interface: interface, peers: peers)
        }
    }

    @Test
    func warnsWhenThereAreNoPeers() throws {
        let configuration = try TunnelConfiguration(interface: interface(addresses: ["10.14.0.2/16"]), peers: [])

        #expect(configuration.warnings == [.noPeers])
    }

    @Test
    func warnsWhenTheInterfaceHasNoAddresses() throws {
        let configuration = try TunnelConfiguration(
            interface: interface(addresses: []),
            peers: [peer(SampleKeys.firstPeerPublicKey(), allowing: ["0.0.0.0/0"])]
        )

        #expect(configuration.warnings == [.interfaceWithoutAddresses])
    }

    @Test
    func warnsAboutPeersThatUseTheInterfaceKeyOrAllowNothing() throws {
        let ownPublicKey = try SampleKeys.interfacePublicKey()
        let silentPeerKey = try SampleKeys.secondPeerPublicKey()

        let configuration = try TunnelConfiguration(
            interface: interface(addresses: ["10.14.0.2/16"]),
            peers: [peer(ownPublicKey, allowing: ["10.0.0.0/8"]), peer(silentPeerKey, allowing: [])]
        )

        #expect(
            configuration.warnings == [
                .peerUsesInterfacePublicKey(ownPublicKey), .peerWithoutAllowedIPs(silentPeerKey),
            ]
        )
    }

    @Test
    func comparesConfigurationsByValue() throws {
        let first = try TunnelConfiguration(interface: interface(addresses: ["10.14.0.2/16"]), peers: [])
        let second = try TunnelConfiguration(interface: interface(addresses: ["10.14.0.2/16"]), peers: [])
        let different = try TunnelConfiguration(interface: interface(addresses: ["10.14.0.3/16"]), peers: [])

        #expect(first == second)
        #expect(first != different)
    }

    private func interface(addresses: [String]) throws -> InterfaceConfiguration {
        try InterfaceConfiguration(
            privateKey: SampleKeys.interfacePrivateKey(),
            addresses: addresses.map { try IPNetwork($0) }
        )
    }

    private func peer(_ publicKey: PublicKey, allowing networks: [String]) throws -> PeerConfiguration {
        try PeerConfiguration(publicKey: publicKey, allowedIPs: AllowedIPs(networks.map { try IPNetwork($0) }))
    }
}
