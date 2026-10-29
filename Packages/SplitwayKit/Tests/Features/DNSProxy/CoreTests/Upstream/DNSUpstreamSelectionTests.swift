import DNSProxy
import SharedKernel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct DNSUpstreamSelectionTests {
    @Test
    func usesTheConfiguredServersThatTheTunnelCarries() throws {
        let configuration = try Self.configuration(dns: "198.51.100.53, 10.0.0.53", allowedIPs: "0.0.0.0/0")

        let selection = DNSUpstreamSelection(for: configuration)

        #expect(selection?.servers == [try IPAddress("198.51.100.53"), try IPAddress("10.0.0.53")])
    }

    @Test
    func skipsConfiguredServersOutsideTheAllowedIPs() throws {
        let configuration = try Self.configuration(dns: "198.51.100.53, 10.0.0.53", allowedIPs: "10.0.0.0/8")

        let selection = DNSUpstreamSelection(for: configuration)

        #expect(selection?.servers == [try IPAddress("10.0.0.53")])
    }

    @Test
    func skipsConfiguredServersOfAFamilyTheTunnelHasNoAddressFor() throws {
        let configuration = try Self.configuration(dns: "2001:db8::53, 198.51.100.53", allowedIPs: "0.0.0.0/0, ::/0")

        let selection = DNSUpstreamSelection(for: configuration)

        #expect(selection?.servers == [try IPAddress("198.51.100.53")])
    }

    @Test
    func fallsBackToTheDefaultServerThroughTheTunnel() throws {
        let configuration = try Self.configuration(dns: nil, allowedIPs: "0.0.0.0/0")

        let selection = DNSUpstreamSelection(for: configuration)

        #expect(selection?.servers == [DNSUpstreamSelection.defaultFallbackServer])
        #expect(DNSUpstreamSelection.defaultFallbackServer == (try IPAddress("1.1.1.1")))
    }

    @Test
    func fallsBackToAConfiguredFallbackWhenNoTunnelServerIsCarried() throws {
        let configuration = try Self.configuration(dns: "2001:db8::53", allowedIPs: "0.0.0.0/0")
        let fallbackServer = try IPAddress("9.9.9.9")

        let selection = DNSUpstreamSelection(for: configuration, fallbackServer: fallbackServer)

        #expect(selection?.servers == [fallbackServer])
    }

    @Test
    func findsNoUpstreamWhenTheTunnelCarriesNoServer() throws {
        let configuration = try Self.configuration(dns: "192.168.1.1", allowedIPs: "10.0.0.0/8")

        #expect(DNSUpstreamSelection(for: configuration) == nil)
    }

    private static func configuration(dns: String?, allowedIPs: String) throws -> TunnelConfiguration {
        let dnsLine = dns.map { servers in "DNS = \(servers)\n" } ?? ""
        let text =
            "[Interface]\nPrivateKey = \(SampleKeys.interfacePrivateKeyText)\nAddress = 10.14.0.2/16\n\(dnsLine)\n"
            + "[Peer]\nPublicKey = \(SampleKeys.firstPeerPublicKeyText)\nAllowedIPs = \(allowedIPs)\n"
        return try #require(WgQuickConfigurationParser.parse(text).configuration)
    }
}
