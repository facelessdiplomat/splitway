import SharedKernel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEngine

@Suite
struct UAPIConfigurationEncoderTests {
    @Test
    func encodesEveryFieldOfTheFullFixture() throws {
        let configuration = try Self.configuration(of: WgQuickFixtures.full)
        let firstPeer = try SampleKeys.firstPeerPublicKey()
        let endpoint = ResolvedEndpoint(address: try IPAddress("2001:db8::1"), port: try NetworkPort(51820))

        let uapi = UAPIConfigurationEncoder.encode(configuration, resolvedEndpoints: [firstPeer: endpoint])

        #expect(
            uapi.text == """
                private_key=\(try SampleKeys.interfacePrivateKey().hexEncodedText)
                listen_port=51820
                replace_peers=true
                public_key=\(firstPeer.hexEncodedText)
                preshared_key=\(try SampleKeys.presharedKey().hexEncodedText)
                endpoint=[2001:db8::1]:51820
                persistent_keepalive_interval=25
                replace_allowed_ips=true
                allowed_ip=0.0.0.0/0
                allowed_ip=::/0

                """
        )
    }

    @Test
    func encodesEveryPeerInOrder() throws {
        let configuration = try Self.configuration(of: WgQuickFixtures.multiplePeers)
        let firstPeer = try SampleKeys.firstPeerPublicKey()
        let secondPeer = try SampleKeys.secondPeerPublicKey()

        let uapi = UAPIConfigurationEncoder.encode(
            configuration,
            resolvedEndpoints: [
                firstPeer: ResolvedEndpoint(address: try IPAddress("203.0.113.10"), port: try NetworkPort(51820)),
                secondPeer: ResolvedEndpoint(address: try IPAddress("203.0.113.20"), port: try NetworkPort(51820)),
            ]
        )

        #expect(
            uapi.text == """
                private_key=\(try SampleKeys.interfacePrivateKey().hexEncodedText)
                replace_peers=true
                public_key=\(firstPeer.hexEncodedText)
                endpoint=203.0.113.10:51820
                replace_allowed_ips=true
                allowed_ip=10.0.0.0/24
                public_key=\(secondPeer.hexEncodedText)
                endpoint=203.0.113.20:51820
                replace_allowed_ips=true
                allowed_ip=10.1.0.0/24

                """
        )
    }

    @Test
    func leavesOutEndpointsThatWereNotResolved() throws {
        let uapi = UAPIConfigurationEncoder.encode(
            try Self.configuration(of: WgQuickFixtures.minimal), resolvedEndpoints: [:])

        #expect(!uapi.text.contains("endpoint="))
    }

    @Test
    func sendsAllowedIPsWithoutHostBits() throws {
        let fixture = WgQuickFixtures.minimal.replacingOccurrences(of: "0.0.0.0/0", with: "10.1.2.3/24")

        let uapi = UAPIConfigurationEncoder.encode(try Self.configuration(of: fixture), resolvedEndpoints: [:])

        #expect(uapi.text.contains("allowed_ip=10.1.2.0/24\n"))
    }

    @Test
    func hidesTheConfigurationFromEveryTextualRepresentation() throws {
        let uapi = UAPIConfigurationEncoder.encode(
            try Self.configuration(of: WgQuickFixtures.full), resolvedEndpoints: [:])
        let privateKeyHex = try SampleKeys.interfacePrivateKey().hexEncodedText
        var dumped = ""
        dump(uapi, to: &dumped)

        for representation in [String(describing: uapi), String(reflecting: uapi), "\(uapi)", dumped] {
            #expect(!representation.contains(privateKeyHex))
        }
    }

    private static func configuration(of fixture: String) throws -> TunnelConfiguration {
        try #require(WgQuickConfigurationParser.parse(fixture).configuration)
    }
}
