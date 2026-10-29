import SharedKernel
import Testing
import TunnelConfiguration

@Suite
struct PrivateNetworkExclusionTests {
    private static let officialClientPublicIPv4Networks = [
        "0.0.0.0/5", "8.0.0.0/7", "11.0.0.0/8", "12.0.0.0/6", "16.0.0.0/4", "32.0.0.0/3", "64.0.0.0/2",
        "128.0.0.0/3", "160.0.0.0/5", "168.0.0.0/6", "172.0.0.0/12", "172.32.0.0/11", "172.64.0.0/10",
        "172.128.0.0/9", "173.0.0.0/8", "174.0.0.0/7", "176.0.0.0/4", "192.0.0.0/9", "192.128.0.0/11",
        "192.160.0.0/13", "192.169.0.0/16", "192.170.0.0/15", "192.172.0.0/14", "192.176.0.0/12",
        "192.192.0.0/10", "193.0.0.0/8", "194.0.0.0/7", "196.0.0.0/6", "200.0.0.0/5", "208.0.0.0/4",
    ]

    @Test
    func matchesTheOfficialClientsPublicNetworkList() {
        #expect(PrivateNetworkExclusion.publicIPv4Networks.map(\.description) == Self.officialClientPublicIPv4Networks)
    }

    @Test
    func replacesTheIPv4DefaultRouteInPlaceAndKeepsPrivateDNSServersReachable() throws {
        let allowedIPs = try allowedIPs("0.0.0.0/0", "::/0")
        let dnsServers = [try IPAddress("10.64.0.1"), try IPAddress("1.1.1.1")]

        let excluded = PrivateNetworkExclusion.applying(to: allowedIPs, keepingReachable: dnsServers)

        #expect(
            excluded.networks.map(\.description) == Self.officialClientPublicIPv4Networks + ["::/0", "10.64.0.1/32"])
    }

    @Test
    func recognizesWhetherTheExclusionIsAppliedOrApplicable() throws {
        let fullTunnel = try allowedIPs("0.0.0.0/0")
        let excluded = PrivateNetworkExclusion.applying(to: fullTunnel, keepingReachable: [])
        let splitTunnel = try allowedIPs("10.0.0.0/8", "192.168.1.0/24")

        #expect(!PrivateNetworkExclusion.isApplied(to: fullTunnel))
        #expect(PrivateNetworkExclusion.isApplicable(to: fullTunnel))
        #expect(PrivateNetworkExclusion.isApplied(to: excluded))
        #expect(PrivateNetworkExclusion.isApplicable(to: excluded))
        #expect(!PrivateNetworkExclusion.isApplicable(to: splitTunnel))
    }

    @Test
    func recognizesTheOfficialClientsListWrittenByHand() throws {
        let handWritten = AllowedIPs(try Self.officialClientPublicIPv4Networks.map { try IPNetwork($0) })

        #expect(PrivateNetworkExclusion.isApplied(to: handWritten))
    }

    @Test(arguments: [
        ["0.0.0.0/0", "::/0"], ["::/0", "0.0.0.0/0"], ["0.0.0.0/0"], ["10.0.0.0/8", "0.0.0.0/0", "fd00::/8"],
    ])
    func restoresTheOriginalListWhenTheExclusionIsRemoved(_ networks: [String]) throws {
        let original = AllowedIPs(try networks.map { try IPNetwork($0) })
        let dnsServers = [try IPAddress("10.64.0.1")]

        let excluded = PrivateNetworkExclusion.applying(to: original, keepingReachable: dnsServers)
        let restored = PrivateNetworkExclusion.removing(from: excluded, dnsServers: dnsServers)

        #expect(restored == original)
    }

    @Test
    func leavesConfigurationsWithoutTheDefaultRouteUnchanged() throws {
        let splitTunnel = try allowedIPs("10.0.0.0/8", "::/0")

        #expect(PrivateNetworkExclusion.applying(to: splitTunnel, keepingReachable: []) == splitTunnel)
        #expect(PrivateNetworkExclusion.removing(from: splitTunnel, dnsServers: []) == splitTunnel)
    }

    @Test
    func routesNoPrivateAddressThroughTheTunnelExceptDNSServers() throws {
        let excluded = PrivateNetworkExclusion.applying(
            to: try allowedIPs("0.0.0.0/0"),
            keepingReachable: [try IPAddress("192.168.1.1")]
        )
        let routed = excluded.networkSet

        #expect(!routed.contains(try IPAddress("10.1.2.3")))
        #expect(!routed.contains(try IPAddress("172.20.0.1")))
        #expect(!routed.contains(try IPAddress("224.0.0.251")))
        #expect(routed.contains(try IPAddress("192.168.1.1")))
        #expect(routed.contains(try IPAddress("8.8.8.8")))
    }

    private func allowedIPs(_ networks: String...) throws -> AllowedIPs {
        AllowedIPs(try networks.map { try IPNetwork($0) })
    }
}
