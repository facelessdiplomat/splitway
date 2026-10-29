import SharedKernel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct WgQuickParserValidConfigurationTests {
    @Test
    func parsesAMinimalConfiguration() throws {
        let configuration = try parsedConfiguration(WgQuickFixtures.minimal)

        #expect(configuration.interface.privateKey == (try SampleKeys.interfacePrivateKey()))
        #expect(configuration.interface.addresses == [try IPNetwork("10.14.0.2/16")])
        #expect(configuration.peers.map(\.publicKey) == [try SampleKeys.firstPeerPublicKey()])
        #expect(configuration.peers.first?.allowedIPs.networks == [try IPNetwork("0.0.0.0/0")])
        #expect(configuration.peers.first?.endpoint == (try Endpoint("vpn.example.com:51820")))
    }

    @Test
    func parsesEverySupportedKey() throws {
        let configuration = try parsedConfiguration(WgQuickFixtures.full)
        let interface = configuration.interface
        let peer = try #require(configuration.peers.first)

        #expect(interface.addresses == [try IPNetwork("10.14.0.2/16"), try IPNetwork("fd00::2/64")])
        #expect(interface.listenPort == (try NetworkPort(51_820)))
        #expect(interface.mtu == (try MTU(1_420)))
        #expect(interface.dns.servers == [try IPAddress("1.1.1.1"), try IPAddress("2606:4700:4700::1111")])
        #expect(interface.dns.searchDomains == [try DomainName("corp.example")])
        #expect(peer.presharedKey == (try SampleKeys.presharedKey()))
        #expect(peer.allowedIPs.networks == [try IPNetwork("0.0.0.0/0"), try IPNetwork("::/0")])
        #expect(peer.endpoint == (try Endpoint("[2001:db8::1]:51820")))
        #expect(peer.persistentKeepalive == (try PersistentKeepalive(seconds: 25)))
    }

    @Test
    func keepsPeersInTheOrderTheyAreWritten() throws {
        let configuration = try parsedConfiguration(WgQuickFixtures.multiplePeers)

        #expect(
            configuration.peers.map(\.publicKey) == [
                try SampleKeys.firstPeerPublicKey(), try SampleKeys.secondPeerPublicKey(),
            ]
        )
    }

    @Test
    func acceptsCommercialProviderConfigurations() throws {
        let configuration = try parsedConfiguration(WgQuickFixtures.commercialProviderStyle)

        #expect(configuration.interface.dns.servers == [try IPAddress("192.0.2.53"), try IPAddress("198.51.100.53")])
        #expect(configuration.peers.first?.endpoint == (try Endpoint("vpn-01.prod.example.net:51820")))
    }

    @Test
    func toleratesWindowsLineEndingsAndAByteOrderMark() throws {
        let configuration = try parsedConfiguration(WgQuickFixtures.windowsLineEndingsWithByteOrderMark)

        #expect(configuration == (try parsedConfiguration(WgQuickFixtures.minimal)))
    }

    @Test
    func readsSectionsAndKeysCaseInsensitivelyAndIgnoresTrailingComments() throws {
        let configuration = try parsedConfiguration(WgQuickFixtures.mixedCaseWithTrailingComments)

        #expect(configuration.interface.addresses == [try IPNetwork("10.14.0.2/16")])
        #expect(
            configuration.peers.first?.allowedIPs.networks == [
                try IPNetwork("10.0.0.0/8"), try IPNetwork("192.168.0.0/16"),
            ]
        )
    }

    @Test
    func treatsZeroPersistentKeepaliveAsDisabled() throws {
        let text = WgQuickFixtures.minimal + "\nPersistentKeepalive = 0"

        #expect(try parsedConfiguration(text).peers.first?.persistentKeepalive == nil)
    }

    private func parsedConfiguration(_ text: String) throws -> TunnelConfiguration {
        let result = WgQuickConfigurationParser.parse(text)
        #expect(result.issues.isEmpty)
        return try #require(result.configuration)
    }
}
