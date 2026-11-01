import AppRouting
import ServiceCatalog
import ServiceCatalogTestSupport
import SharedKernel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct ServiceRoutingPlanCompilerTests {
    private let compiler = ServiceRoutingPlanCompiler()

    @Test
    func routesTheSelectedNetworksAndTheFakeNetwork() throws {
        let catalog = try Self.catalog()

        let plan = compiler.compile(
            selection: try Self.selection("telegram"), catalog: catalog, configuration: try Self.configuration())

        #expect(plan.includedRoutes.map(\.description) == ["91.108.4.0/22", "149.154.160.0/20", "198.18.0.0/15"])
        #expect(plan.warnings.isEmpty)
    }

    @Test
    func listsTheShortestDomainsOfTheSelectedServicesOnly() throws {
        let catalog = try Self.catalog()

        let plan = compiler.compile(
            selection: try Self.selection("telegram", "youtube"), catalog: catalog,
            configuration: try Self.configuration()
        )

        #expect(plan.matchDomains.map(\.description) == ["t.me", "telegram.org", "youtube.com"])
    }

    @Test
    func routesOnlyThePartInsideAllowedIPsAndWarnsAboutTheRest() throws {
        let catalog = try Self.catalog()
        let configuration = try Self.configuration(allowedIPs: "10.0.0.0/8, 91.108.4.0/23")

        let plan = compiler.compile(
            selection: try Self.selection("telegram"), catalog: catalog, configuration: configuration)

        #expect(plan.includedRoutes.map(\.description) == ["91.108.4.0/23", "198.18.0.0/15"])
        #expect(
            plan.warnings.contains(
                .networksOutsideAllowedIPs(
                    try ServiceIdentifier("telegram"),
                    [try IPNetwork("91.108.6.0/23"), try IPNetwork("149.154.160.0/20")])
            )
        )
        #expect(plan.warnings.contains(.allowedIPsWithoutDefaultRoute))
    }

    @Test
    func warnsAboutAnEmptySelection() throws {
        let plan = compiler.compile(
            selection: ServiceSelection([]), catalog: try Self.catalog(), configuration: try Self.configuration())

        #expect(plan.warnings == [.emptySelection])
        #expect(plan.matchDomains.isEmpty)
        #expect(plan.includedRoutes.map(\.description) == ["198.18.0.0/15"])
    }

    @Test
    func placesTheVirtualResolverInsideTheFakeNetwork() throws {
        let plan = compiler.compile(
            selection: try Self.selection("telegram"), catalog: try Self.catalog(),
            configuration: try Self.configuration())

        #expect(plan.fakeIPv4Network == (try IPNetwork("198.18.0.0/15")))
        #expect(plan.virtualResolver == (try IPAddress("198.18.0.2")))
    }

    @Test
    func movesTheFakeNetworkAwayFromTheTunnelAddresses() throws {
        let configuration = try Self.configuration(addresses: "198.18.5.2/24")

        let plan = compiler.compile(
            selection: try Self.selection("telegram"), catalog: try Self.catalog(), configuration: configuration)

        #expect(plan.fakeIPv4Network == (try IPNetwork("198.19.0.0/16")))
        #expect(plan.virtualResolver == (try IPAddress("198.19.0.2")))
        #expect(plan.warnings == [.fakeNetworkConflict])
    }

    @Test(arguments: [("10.64.0.1", "10.64.0.1"), ("2606:4700::1111, 10.64.0.1", "10.64.0.1"), (nil, "1.1.1.1")])
    func forwardsQueriesToTheFirstIPv4ResolverOfTheTunnel(dns: String?, upstream: String) throws {
        let plan = compiler.compile(
            selection: try Self.selection("telegram"), catalog: try Self.catalog(),
            configuration: try Self.configuration(dns: dns)
        )

        #expect(plan.upstreamResolver == (try IPAddress(upstream)))
    }

    @Test
    func warnsWhenTheResolverIsOutsideAllowedIPs() throws {
        let configuration = try Self.configuration(dns: nil, allowedIPs: "10.0.0.0/8, 91.108.4.0/22, 149.154.160.0/20")

        let plan = compiler.compile(
            selection: try Self.selection("telegram"), catalog: try Self.catalog(), configuration: configuration)

        #expect(plan.warnings.contains(.resolverOutsideAllowedIPs(try IPAddress("1.1.1.1"))))
    }

    @Test
    func staysQuietAboutTheResolverWhenNoDomainIsSelected() throws {
        let configuration = try Self.configuration(dns: nil, allowedIPs: "10.0.0.0/8")

        let plan = compiler.compile(
            selection: ServiceSelection([]), catalog: try Self.catalog(), configuration: configuration)

        #expect(plan.warnings == [.emptySelection])
    }

    @Test
    func addsAFakeIPv6NetworkOnlyWhenTheTunnelHasIPv6() throws {
        let catalog = try Self.catalog()
        let dualStack = try Self.configuration(addresses: "10.14.0.2/16, fd00::2/128", allowedIPs: "0.0.0.0/0, ::/0")

        let withIPv6 = compiler.compile(
            selection: try Self.selection("telegram"), catalog: catalog, configuration: dualStack)
        let withoutIPv6 = compiler.compile(
            selection: try Self.selection("telegram"), catalog: catalog, configuration: try Self.configuration())

        #expect(withIPv6.fakeIPv6Network == (try IPNetwork("2001:2::/48")))
        #expect(withIPv6.includedRoutes.contains(try IPNetwork("2001:2::/48")))
        #expect(withoutIPv6.fakeIPv6Network == nil)
    }

    @Test
    func compilesTheSameSelectionToTheSamePlanWhateverItsOrder() throws {
        let catalog = try Self.catalog()
        let configuration = try Self.configuration()

        let forward = compiler.compile(
            selection: try Self.selection("telegram", "youtube"), catalog: catalog, configuration: configuration)
        let backward = compiler.compile(
            selection: try Self.selection("youtube", "telegram"), catalog: catalog, configuration: configuration)

        #expect(forward == backward)
    }

    private static func catalog() throws -> ServiceCatalog {
        ServiceCatalog(services: [
            try ServiceCatalogFixtures.profile(
                id: "telegram",
                name: "Telegram",
                domains: ["telegram.org", "t.me", "web.telegram.org"],
                networks: ["91.108.4.0/22", "149.154.160.0/20"]
            ),
            try ServiceCatalogFixtures.profile(id: "youtube", name: "YouTube", domains: ["youtube.com"]),
        ])
    }

    private static func selection(_ identifiers: String...) throws -> ServiceSelection {
        ServiceSelection(try identifiers.map { identifier in try ServiceIdentifier(identifier) })
    }

    private static func configuration(
        addresses: String = "10.14.0.2/16",
        dns: String? = "10.64.0.1",
        allowedIPs: String = "0.0.0.0/0"
    ) throws -> TunnelConfiguration {
        var lines = ["[Interface]", "PrivateKey = \(SampleKeys.interfacePrivateKeyText)", "Address = \(addresses)"]
        if let dns {
            lines.append("DNS = \(dns)")
        }
        lines += [
            "[Peer]", "PublicKey = \(SampleKeys.firstPeerPublicKeyText)", "AllowedIPs = \(allowedIPs)",
            "Endpoint = 203.0.113.10:51820",
        ]
        return try #require(WgQuickConfigurationParser.parse(lines.joined(separator: "\n")).configuration)
    }
}
