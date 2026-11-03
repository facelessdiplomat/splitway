import AppRouting
import PacketTunnel
import SharedKernel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct TunnelNetworkPlannerTests {
    private static let peerPublicKeys = [SampleKeys.firstPeerPublicKeyText, SampleKeys.secondPeerPublicKeyText]

    @Test
    func routesAnIPv4OnlyFullTunnelAndBlocksIPv6Leaks() throws {
        let configuration = try Self.configuration("Address = 10.14.0.2/16", peers: ["0.0.0.0/0"])

        let plan = try TunnelNetworkPlanner.plan(for: configuration, routedBy: .default)

        #expect(
            plan.ipv4
                == TunnelAddressFamilyPlan(
                    addresses: [try IPNetwork("10.14.0.2/16")],
                    includedRoutes: [.ipv4DefaultRoute]
                )
        )
        #expect(
            plan.ipv6
                == TunnelAddressFamilyPlan(
                    addresses: [IPv6LeakProtection.placeholderInterfaceAddress],
                    includedRoutes: [.ipv6GlobalUnicast]
                )
        )
    }

    @Test
    func routesBothFamiliesOfADualStackTunnel() throws {
        let configuration = try Self.configuration("Address = 10.14.0.2/16, fd00::2/64", peers: ["0.0.0.0/0, ::/0"])

        let plan = try TunnelNetworkPlanner.plan(for: configuration, routedBy: .default)

        #expect(
            plan.ipv6
                == TunnelAddressFamilyPlan(
                    addresses: [try IPNetwork("fd00::2/64")], includedRoutes: [.ipv6DefaultRoute])
        )
    }

    @Test
    func blocksIPv6LeaksWithTheTunnelsOwnAddressWhenIPv6IsRoutedOnlyInPart() throws {
        let configuration = try Self.configuration(
            "Address = 10.14.0.2/16, fd00::2/64",
            peers: ["0.0.0.0/0, fd00::/64"]
        )

        let plan = try TunnelNetworkPlanner.plan(for: configuration, routedBy: .default)

        #expect(
            plan.ipv6
                == TunnelAddressFamilyPlan(
                    addresses: [try IPNetwork("fd00::2/64")],
                    includedRoutes: [.ipv6GlobalUnicast, try IPNetwork("fd00::/64")]
                )
        )
    }

    @Test
    func mergesOverlappingAllowedIPsAndLeavesIPv6OfASplitTunnelAlone() throws {
        let configuration = try Self.configuration(
            "Address = 10.0.0.2/32",
            peers: ["10.0.0.0/24, 192.168.5.0/24", "10.0.0.0/16"]
        )

        let plan = try TunnelNetworkPlanner.plan(for: configuration, routedBy: .default)

        #expect(plan.ipv4?.includedRoutes == [try IPNetwork("10.0.0.0/16"), try IPNetwork("192.168.5.0/24")])
        #expect(plan.ipv6 == nil)
    }

    @Test
    func routesPublicNetworksWhenLocalNetworksAreExcluded() throws {
        let publicNetworks = PrivateNetworkExclusion.publicIPv4Networks
        let configuration = try Self.configuration(
            "Address = 10.14.0.2/16",
            peers: [publicNetworks.map(\.description).joined(separator: ", ")]
        )

        let plan = try TunnelNetworkPlanner.plan(for: configuration, routedBy: .default)

        let expectedRoutes = IPNetworkSet(publicNetworks + [try IPNetwork("10.14.0.0/16")]).networks
        #expect(plan.ipv4?.includedRoutes == expectedRoutes)
        #expect(plan.ipv6?.includedRoutes == [.ipv6GlobalUnicast])
    }

    @Test
    func sendsEveryDomainToTheConfiguredDNSServers() throws {
        let configuration = try Self.configuration(
            "Address = 10.14.0.2/16\nDNS = 1.1.1.1, corp.example",
            peers: ["0.0.0.0/0"]
        )

        let plan = try TunnelNetworkPlanner.plan(for: configuration, routedBy: .default)

        #expect(
            plan.dns
                == TunnelDNSPlan(
                    servers: [try IPAddress("1.1.1.1")],
                    searchDomains: [try DomainName("corp.example")],
                    scope: .allDomains
                )
        )
    }

    @Test
    func leavesDNSToTheSystemWithoutConfiguredServers() throws {
        let configuration = try Self.configuration("Address = 10.14.0.2/16", peers: ["0.0.0.0/0"])

        #expect(try TunnelNetworkPlanner.plan(for: configuration, routedBy: .default).dns == nil)
    }

    @Test
    func derivesTheMTUFromThePathUnlessTheConfigurationSetsIt() throws {
        let derived = try Self.configuration("Address = 10.14.0.2/16", peers: ["0.0.0.0/0"])
        let fixed = try Self.configuration("Address = 10.14.0.2/16\nMTU = 1380", peers: ["0.0.0.0/0"])

        #expect(try TunnelNetworkPlanner.plan(for: derived, routedBy: .default).mtu == .pathMTUWithOverhead(bytes: 80))
        #expect(try TunnelNetworkPlanner.plan(for: fixed, routedBy: .default).mtu == .fixed(try MTU(1380)))
    }

    @Test
    func rejectsRoutingModesThatThePacketTunnelDoesNotServe() throws {
        let configuration = try Self.configuration("Address = 10.14.0.2/16", peers: ["0.0.0.0/0"])
        let applications = RoutingPolicy(mode: .selectedApplications(ApplicationSelection([])))

        #expect(throws: TunnelNetworkPlanError.routingModeNotSupported(.selectedApplications)) {
            try TunnelNetworkPlanner.plan(for: configuration, routedBy: applications)
        }
    }

    @Test
    func rejectsIPv4RoutesWithoutAnIPv4Address() throws {
        let configuration = try Self.configuration("Address = fd00::2/64", peers: ["0.0.0.0/0, ::/0"])

        #expect(throws: TunnelNetworkPlanError.missingInterfaceAddress(.ipv4)) {
            try TunnelNetworkPlanner.plan(for: configuration, routedBy: .default)
        }
    }

    private static func configuration(_ interfaceLines: String, peers: [String]) throws -> TunnelConfiguration {
        let peerSections = zip(peerPublicKeys, peers).map { publicKey, allowedIPs in
            "[Peer]\nPublicKey = \(publicKey)\nAllowedIPs = \(allowedIPs)\n"
        }
        let text =
            "[Interface]\nPrivateKey = \(SampleKeys.interfacePrivateKeyText)\n\(interfaceLines)\n\n"
            + peerSections.joined(separator: "\n")
        return try #require(WgQuickConfigurationParser.parse(text).configuration)
    }
}
