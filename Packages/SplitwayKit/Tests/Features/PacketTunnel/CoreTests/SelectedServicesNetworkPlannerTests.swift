import AppRouting
import PacketTunnel
import ServiceCatalog
import ServiceCatalogTestSupport
import SharedKernel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct SelectedServicesNetworkPlannerTests {
    @Test
    func routesTheSelectedNetworksAndTheFakeNetworkWithoutADefaultRoute() throws {
        let configuration = try Self.configuration(address: "10.14.0.2/16", allowedIPs: "0.0.0.0/0")
        let servicePlan = try Self.servicePlan(networks: ["91.108.4.0/22"], configuration: configuration)

        let plan = try SelectedServicesNetworkPlanner.plan(for: servicePlan, configuration: configuration)

        #expect(
            plan.ipv4
                == TunnelAddressFamilyPlan(
                    addresses: [try IPNetwork("10.14.0.2/16")],
                    includedRoutes: [try IPNetwork("91.108.4.0/22"), .ipv4BenchmarkingRange]
                )
        )
        #expect(plan.ipv6 == nil)
        #expect(plan.mtu == .pathMTUWithOverhead(bytes: TunnelMTU.wireGuardOverheadBytes))
    }

    @Test
    func sendsOnlyTheSelectedDomainsToTheVirtualResolver() throws {
        let configuration = try Self.configuration(address: "10.14.0.2/16", allowedIPs: "0.0.0.0/0")
        let servicePlan = try Self.servicePlan(domains: ["telegram.org", "t.me"], configuration: configuration)

        let plan = try SelectedServicesNetworkPlanner.plan(for: servicePlan, configuration: configuration)

        #expect(
            plan.dns
                == TunnelDNSPlan(
                    servers: [try IPAddress("198.18.0.2")],
                    searchDomains: [],
                    scope: .matchingDomains([try DomainName("t.me"), try DomainName("telegram.org")])
                )
        )
    }

    @Test
    func leavesTheSystemResolverAloneWhenNoServiceHasDomains() throws {
        let configuration = try Self.configuration(address: "10.14.0.2/16", allowedIPs: "0.0.0.0/0")
        let servicePlan = try Self.servicePlan(domains: [], networks: ["91.108.4.0/22"], configuration: configuration)

        let plan = try SelectedServicesNetworkPlanner.plan(for: servicePlan, configuration: configuration)

        #expect(plan.dns == nil)
    }

    @Test
    func routesIPv6ServicesAndFakeAddressesThroughTheTunnelsOwnAddress() throws {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.full).configuration)
        let servicePlan = try Self.servicePlan(networks: ["2001:67c:4e8::/48"], configuration: configuration)

        let plan = try SelectedServicesNetworkPlanner.plan(for: servicePlan, configuration: configuration)

        #expect(
            plan.ipv6
                == TunnelAddressFamilyPlan(
                    addresses: [try IPNetwork("fd00::2/64")],
                    includedRoutes: [.ipv6BenchmarkingRange, try IPNetwork("2001:67c:4e8::/48")]
                )
        )
        #expect(plan.mtu == .fixed(try MTU(1420)))
    }

    @Test
    func blocksTheIPv6NetworksOfServicesWhenTheTunnelHasNoIPv6Address() throws {
        let configuration = try Self.configuration(address: "10.14.0.2/16", allowedIPs: "0.0.0.0/0, ::/0")
        let servicePlan = try Self.servicePlan(networks: ["2001:67c:4e8::/48"], configuration: configuration)

        let plan = try SelectedServicesNetworkPlanner.plan(for: servicePlan, configuration: configuration)

        #expect(
            plan.ipv6
                == TunnelAddressFamilyPlan(
                    addresses: [IPv6LeakProtection.placeholderInterfaceAddress],
                    includedRoutes: [try IPNetwork("2001:67c:4e8::/48")]
                )
        )
    }

    @Test
    func needsAnIPv4AddressForTheVirtualResolver() throws {
        let configuration = try Self.configuration(address: "fd00::2/64", allowedIPs: "::/0")
        let servicePlan = try Self.servicePlan(configuration: configuration)

        #expect(throws: TunnelNetworkPlanError.missingInterfaceAddress(.ipv4)) {
            try SelectedServicesNetworkPlanner.plan(for: servicePlan, configuration: configuration)
        }
    }

    private static func servicePlan(
        domains: [String] = ["telegram.org"],
        networks: [String] = [],
        configuration: TunnelConfiguration
    ) throws -> ServiceRoutingPlan {
        let telegram = try ServiceCatalogFixtures.profile(
            id: "telegram", name: "Telegram", domains: domains, networks: networks)
        return ServiceRoutingPlanCompiler().compile(
            selection: ServiceSelection([telegram.id]),
            catalog: ServiceCatalog(services: [telegram]),
            configuration: configuration
        )
    }

    private static func configuration(address: String, allowedIPs: String) throws -> TunnelConfiguration {
        let text = """
            [Interface]
            PrivateKey = \(SampleKeys.interfacePrivateKeyText)
            Address = \(address)

            [Peer]
            PublicKey = \(SampleKeys.firstPeerPublicKeyText)
            AllowedIPs = \(allowedIPs)
            Endpoint = 203.0.113.10:51820
            """
        return try #require(WgQuickConfigurationParser.parse(text).configuration)
    }
}
