import SharedKernel
import Testing
import TransparentProxy
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct TransparentProxyNetworkPlanTests {
    private static let peerPublicKeys = [SampleKeys.firstPeerPublicKeyText, SampleKeys.secondPeerPublicKeyText]
    private static let localDestinations = IPNetworkSet(
        IPNetwork.loopbackNetworks + IPNetwork.linkLocalNetworks + IPNetwork.multicastNetworks
    )

    @Test
    func includesOnlyThePublicNetworksOfAFullTunnelThatExcludesLocalNetworks() throws {
        let publicNetworks = PrivateNetworkExclusion.publicIPv4Networks.map(String.init(describing:))
        let configuration = try Self.configuration(peers: ["AllowedIPs = \(publicNetworks.joined(separator: ", "))"])

        let plan = TransparentProxyNetworkPlan(for: configuration, resolvedEndpointAddresses: [])

        let includedIPv4Networks = plan.includedNetworks.networks.filter { network in network.family == .ipv4 }
        #expect(includedIPv4Networks == PrivateNetworkExclusion.publicIPv4Networks)
    }

    @Test
    func blocksIPv6LeaksOfAFullTunnelThatCarriesOnlyIPv4() throws {
        let configuration = try Self.configuration(peers: ["AllowedIPs = 0.0.0.0/0"])

        let plan = TransparentProxyNetworkPlan(for: configuration, resolvedEndpointAddresses: [])

        #expect(plan.includedNetworks == IPNetworkSet([.ipv4DefaultRoute, .ipv6GlobalUnicast]))
    }

    @Test
    func includesBothDefaultRoutesOfADualStackTunnel() throws {
        let configuration = try Self.configuration(peers: ["AllowedIPs = 0.0.0.0/0, ::/0"])

        let plan = TransparentProxyNetworkPlan(for: configuration, resolvedEndpointAddresses: [])

        #expect(plan.includedNetworks == IPNetworkSet([.ipv4DefaultRoute, .ipv6DefaultRoute]))
    }

    @Test
    func mergesTheAllowedIPsOfEveryPeer() throws {
        let configuration = try Self.configuration(peers: [
            "AllowedIPs = 10.0.0.0/24", "AllowedIPs = 10.0.1.0/24, 192.168.50.0/24",
        ])

        let plan = TransparentProxyNetworkPlan(for: configuration, resolvedEndpointAddresses: [])

        #expect(
            plan.includedNetworks == IPNetworkSet([try IPNetwork("10.0.0.0/23"), try IPNetwork("192.168.50.0/24")]))
    }

    @Test
    func excludesLoopbackLinkLocalAndMulticastDestinations() throws {
        let configuration = try Self.configuration(peers: ["AllowedIPs = 0.0.0.0/0, ::/0"])

        let plan = TransparentProxyNetworkPlan(for: configuration, resolvedEndpointAddresses: [])

        #expect(plan.excludedNetworks == Self.localDestinations)
    }

    @Test
    func excludesTheAddressOfAnEndpointGivenAsAnAddress() throws {
        let configuration = try Self.configuration(peers: [
            "AllowedIPs = 0.0.0.0/0\nEndpoint = 203.0.113.7:51820", "AllowedIPs = ::/0\nEndpoint = [2001:db8::7]:51820",
        ])

        let plan = TransparentProxyNetworkPlan(for: configuration, resolvedEndpointAddresses: [])

        let endpointHosts = [
            IPNetwork(host: try IPAddress("203.0.113.7")), IPNetwork(host: try IPAddress("2001:db8::7")),
        ]
        #expect(plan.excludedNetworks == Self.localDestinations.union(IPNetworkSet(endpointHosts)))
    }

    @Test
    func excludesTheResolvedAddressesOfAnEndpointGivenByName() throws {
        let configuration = try Self.configuration(peers: ["AllowedIPs = 0.0.0.0/0\nEndpoint = vpn.example.com:51820"])
        let resolvedAddresses = [try IPAddress("198.51.100.4"), try IPAddress("2001:db8::4")]

        let plan = TransparentProxyNetworkPlan(for: configuration, resolvedEndpointAddresses: resolvedAddresses)

        let endpointHosts = resolvedAddresses.map(IPNetwork.init(host:))
        #expect(plan.excludedNetworks == Self.localDestinations.union(IPNetworkSet(endpointHosts)))
    }

    private static func configuration(peers: [String]) throws -> TunnelConfiguration {
        let peerSections = zip(peerPublicKeys, peers).map { publicKey, peerLines in
            "[Peer]\nPublicKey = \(publicKey)\n\(peerLines)\n"
        }
        let text =
            "[Interface]\nPrivateKey = \(SampleKeys.interfacePrivateKeyText)\nAddress = 10.14.0.2/16\n\n"
            + peerSections.joined(separator: "\n")
        return try #require(WgQuickConfigurationParser.parse(text).configuration)
    }
}
