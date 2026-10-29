extension IPNetwork {
    public static let ipv4DefaultRoute = IPNetwork(address: .ipv4(0), trustedPrefixLength: 0)
    public static let ipv6DefaultRoute = IPNetwork(address: .ipv6(0), trustedPrefixLength: 0)
    public static let ipv6GlobalUnicast = IPNetwork(address: .ipv6(0x2000 << 112), trustedPrefixLength: 3)
}
