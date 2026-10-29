import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct WgQuickSerializerTests {
    private static let validFixtures = [
        WgQuickFixtures.minimal,
        WgQuickFixtures.full,
        WgQuickFixtures.multiplePeers,
        WgQuickFixtures.commercialProviderStyle,
        WgQuickFixtures.mixedCaseWithTrailingComments,
        WgQuickFixtures.windowsLineEndingsWithByteOrderMark,
    ]

    @Test
    func writesTheCanonicalForm() throws {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.full).configuration)

        let expected = """
            [Interface]
            PrivateKey = \(SampleKeys.interfacePrivateKeyText)
            Address = 10.14.0.2/16, fd00::2/64
            ListenPort = 51820
            MTU = 1420
            DNS = 1.1.1.1, 2606:4700:4700::1111, corp.example

            [Peer]
            PublicKey = \(SampleKeys.firstPeerPublicKeyText)
            PresharedKey = \(SampleKeys.presharedKeyText)
            AllowedIPs = 0.0.0.0/0, ::/0
            Endpoint = [2001:db8::1]:51820
            PersistentKeepalive = 25

            """
        #expect(WgQuickConfigurationSerializer.serialize(configuration) == expected)
    }

    @Test
    func omitsValuesThatAreNotSet() throws {
        let interface = try InterfaceConfiguration(privateKey: SampleKeys.interfacePrivateKey())
        let peer = try PeerConfiguration(publicKey: SampleKeys.firstPeerPublicKey())
        let configuration = try TunnelConfiguration(interface: interface, peers: [peer])

        let expected = """
            [Interface]
            PrivateKey = \(SampleKeys.interfacePrivateKeyText)

            [Peer]
            PublicKey = \(SampleKeys.firstPeerPublicKeyText)

            """
        #expect(WgQuickConfigurationSerializer.serialize(configuration) == expected)
    }

    @Test(arguments: validFixtures)
    func roundTripsEveryValidFixture(_ fixture: String) throws {
        let configuration = try #require(WgQuickConfigurationParser.parse(fixture).configuration)

        let reparsed = WgQuickConfigurationParser.parse(WgQuickConfigurationSerializer.serialize(configuration))

        #expect(reparsed.configuration == configuration)
    }

    @Test(arguments: 1...200 as ClosedRange<UInt64>)
    func roundTripsRandomConfigurations(seed: UInt64) throws {
        var generator = RandomTunnelConfigurationGenerator(seed: seed)
        let configuration = try generator.configuration()

        let reparsed = WgQuickConfigurationParser.parse(WgQuickConfigurationSerializer.serialize(configuration))

        #expect(reparsed.errors.isEmpty)
        #expect(reparsed.configuration == configuration)
    }

    @Test
    func producesTheSameTextWhenSerializedTwice() throws {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.multiplePeers).configuration)
        let firstText = WgQuickConfigurationSerializer.serialize(configuration)
        let reparsed = try #require(WgQuickConfigurationParser.parse(firstText).configuration)

        #expect(WgQuickConfigurationSerializer.serialize(reparsed) == firstText)
    }
}
