import NetworkExtension
import PacketTunnel
import SharedKernel

public enum NetworkSettingsMapper {
    private static let tunnelRemoteAddress = "127.0.0.1"
    private static let everyDomain = ""
    private static let ipv4AddressBits = 32

    public static func settings(for plan: TunnelNetworkPlan) -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: tunnelRemoteAddress)
        settings.ipv4Settings = plan.ipv4.map(ipv4Settings)
        settings.ipv6Settings = plan.ipv6.map(ipv6Settings)
        settings.dnsSettings = plan.dns.map(dnsSettings)
        switch plan.mtu {
        case .fixed(let mtu):
            settings.mtu = NSNumber(value: mtu.value)
        case .pathMTUWithOverhead(let overheadBytes):
            settings.tunnelOverheadBytes = NSNumber(value: overheadBytes)
        }
        return settings
    }

    private static func ipv4Settings(for plan: TunnelAddressFamilyPlan) -> NEIPv4Settings {
        let settings = NEIPv4Settings(
            addresses: plan.addresses.map(\.address.description),
            subnetMasks: plan.addresses.map(subnetMask)
        )
        settings.includedRoutes = plan.includedRoutes.map { route in
            NEIPv4Route(destinationAddress: route.address.description, subnetMask: subnetMask(of: route))
        }
        return settings
    }

    private static func ipv6Settings(for plan: TunnelAddressFamilyPlan) -> NEIPv6Settings {
        let settings = NEIPv6Settings(
            addresses: plan.addresses.map(\.address.description),
            networkPrefixLengths: plan.addresses.map { address in NSNumber(value: address.prefixLength) }
        )
        settings.includedRoutes = plan.includedRoutes.map { route in
            NEIPv6Route(
                destinationAddress: route.address.description, networkPrefixLength: NSNumber(value: route.prefixLength))
        }
        return settings
    }

    private static func dnsSettings(for plan: TunnelDNSPlan) -> NEDNSSettings {
        let settings = NEDNSSettings(servers: plan.servers.map(\.description))
        settings.searchDomains = plan.searchDomains.map(\.description)
        switch plan.scope {
        case .allDomains:
            settings.matchDomains = [everyDomain]
        case .matchingDomains(let domains):
            settings.matchDomains = domains.map(\.description)
            settings.matchDomainsNoSearch = true
        }
        return settings
    }

    private static func subnetMask(of network: IPNetwork) -> String {
        SharedKernel.IPAddress.ipv4(UInt32.max << (ipv4AddressBits - network.prefixLength)).description
    }
}
