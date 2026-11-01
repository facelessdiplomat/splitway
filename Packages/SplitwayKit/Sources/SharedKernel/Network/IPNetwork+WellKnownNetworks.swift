extension IPNetwork {
    public static let loopbackNetworks = [
        IPNetwork(address: .ipv4(0x7F00_0000), trustedPrefixLength: 8),
        IPNetwork(address: .ipv6(1), trustedPrefixLength: 128),
    ]

    public static let linkLocalNetworks = [
        IPNetwork(address: .ipv4(0xA9FE_0000), trustedPrefixLength: 16),
        IPNetwork(address: .ipv6(0xFE80 << 112), trustedPrefixLength: 10),
    ]

    public static let privateNetworks = [
        IPNetwork(address: .ipv4(0x0A00_0000), trustedPrefixLength: 8),
        IPNetwork(address: .ipv4(0xAC10_0000), trustedPrefixLength: 12),
        IPNetwork(address: .ipv4(0xC0A8_0000), trustedPrefixLength: 16),
        IPNetwork(address: .ipv6(0xFC00 << 112), trustedPrefixLength: 7),
    ]

    public static let reservedNetworks = [
        IPNetwork(address: .ipv4(0xF000_0000), trustedPrefixLength: 4)
    ]

    public static let ipv4BenchmarkingRange = IPNetwork(address: .ipv4(0xC612_0000), trustedPrefixLength: 15)
    public static let ipv6BenchmarkingRange = IPNetwork(address: .ipv6(0x2001_0002 << 96), trustedPrefixLength: 48)

    public static let multicastNetworks = [
        IPNetwork(address: .ipv4(0xE000_0000), trustedPrefixLength: 4),
        IPNetwork(address: .ipv6(0xFF00 << 112), trustedPrefixLength: 8),
    ]
}
