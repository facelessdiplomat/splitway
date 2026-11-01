import ServiceCatalog
import SharedKernel
import TunnelConfiguration

public enum SelectedServicesNetworkPlanner {
    public static func plan(
        for servicePlan: ServiceRoutingPlan,
        configuration: TunnelConfiguration
    ) throws(TunnelNetworkPlanError) -> TunnelNetworkPlan {
        let addresses = configuration.interface.addresses
        let ipv4Addresses = addresses.filter { address in address.family == .ipv4 }
        guard !ipv4Addresses.isEmpty else { throw .missingInterfaceAddress(.ipv4) }
        return TunnelNetworkPlan(
            ipv4: TunnelAddressFamilyPlan(addresses: ipv4Addresses, includedRoutes: routes(of: .ipv4, in: servicePlan)),
            ipv6: ipv6Plan(addresses: addresses, routes: routes(of: .ipv6, in: servicePlan)),
            dns: dnsPlan(for: servicePlan),
            mtu: TunnelMTU(interface: configuration.interface)
        )
    }

    private static func routes(of family: IPAddressFamily, in servicePlan: ServiceRoutingPlan) -> [IPNetwork] {
        servicePlan.includedRoutes.filter { route in route.family == family }
    }

    private static func ipv6Plan(addresses: [IPNetwork], routes: [IPNetwork]) -> TunnelAddressFamilyPlan? {
        guard !routes.isEmpty else { return nil }
        let ipv6Addresses = addresses.filter { address in address.family == .ipv6 }
        return TunnelAddressFamilyPlan(
            addresses: ipv6Addresses.isEmpty ? [IPv6LeakProtection.placeholderInterfaceAddress] : ipv6Addresses,
            includedRoutes: routes
        )
    }

    private static func dnsPlan(for servicePlan: ServiceRoutingPlan) -> TunnelDNSPlan? {
        guard !servicePlan.matchDomains.isEmpty else { return nil }
        return TunnelDNSPlan(
            servers: [servicePlan.virtualResolver],
            searchDomains: [],
            scope: .matchingDomains(servicePlan.matchDomains)
        )
    }
}
