import SharedKernel
import TunnelConfiguration

public enum IPv6LeakProtection {
    public static let blockedNetwork = IPNetwork.ipv6GlobalUnicast
    public static let placeholderInterfaceAddress = IPNetwork(host: .ipv6(0xFDC6_3A2B_91E4_0000_0000_0000_0000_0001))

    static func isNeeded(for routes: IPNetworkSet) -> Bool {
        capturesAllPublicIPv4(routes) && !routes.contains(blockedNetwork)
    }

    private static func capturesAllPublicIPv4(_ routes: IPNetworkSet) -> Bool {
        PrivateNetworkExclusion.publicIPv4Networks.allSatisfy { network in routes.contains(network) }
    }
}
