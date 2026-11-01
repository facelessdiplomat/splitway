import AppRouting
import SharedKernel
import TunnelConfiguration

public struct ServiceRoutingPlanCompiler: Sendable {
    public static let standardUpstreamResolver = IPAddress.ipv4(0x0101_0101)

    private static let virtualResolverOffset = 2

    private let defaultUpstreamResolver: IPAddress

    public init(defaultUpstreamResolver: IPAddress = Self.standardUpstreamResolver) {
        self.defaultUpstreamResolver = defaultUpstreamResolver
    }

    public func compile(
        selection: ServiceSelection,
        catalog: ServiceCatalog,
        configuration: TunnelConfiguration
    ) -> ServiceRoutingPlan {
        let services = catalog.services(in: selection)
        let allowed = IPNetworkSet(configuration.peers.flatMap(\.allowedIPs.networks))
        let fakeNetworks = FakeNetworkSelection(configuration: configuration)
        let upstream = configuration.interface.dns.servers.first { server in server.family == .ipv4 }
        let domains = DomainSuffixSet(services.flatMap(\.rules.domainSuffixes)).suffixes
        let routes = IPNetworkSet(services.flatMap(\.rules.networks)).intersection(allowed)
            .union(IPNetworkSet(fakeNetworks.networks))
        let upstreamResolver = upstream ?? defaultUpstreamResolver
        return ServiceRoutingPlan(
            includedRoutes: routes.networks,
            matchDomains: domains,
            virtualResolver: fakeNetworks.ipv4.address(atOffset: Self.virtualResolverOffset)
                ?? fakeNetworks.ipv4.firstAddress,
            upstreamResolver: upstreamResolver,
            fakeIPv4Network: fakeNetworks.ipv4,
            fakeIPv6Network: fakeNetworks.ipv6,
            warnings: Self.warnings(
                services: services,
                hasDomains: !domains.isEmpty,
                allowed: allowed,
                upstreamResolver: upstreamResolver,
                fakeNetworks: fakeNetworks
            )
        )
    }

    private static func warnings(
        services: [ServiceProfile],
        hasDomains: Bool,
        allowed: IPNetworkSet,
        upstreamResolver: IPAddress,
        fakeNetworks: FakeNetworkSelection
    ) -> [ServiceRoutingWarning] {
        var warnings: [ServiceRoutingWarning] = services.isEmpty ? [.emptySelection] : []
        for service in services {
            let outside = IPNetworkSet(service.rules.networks).subtracting(allowed)
            if !outside.isEmpty {
                warnings.append(.networksOutsideAllowedIPs(service.id, outside.networks))
            }
        }
        if hasDomains, !allowed.contains(IPNetwork.ipv4DefaultRoute) {
            warnings.append(.allowedIPsWithoutDefaultRoute)
        }
        if !allowed.contains(upstreamResolver) {
            warnings.append(.resolverOutsideAllowedIPs(upstreamResolver))
        }
        if fakeNetworks.hasConflict {
            warnings.append(.fakeNetworkConflict)
        }
        return warnings
    }
}
