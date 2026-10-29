extension IPAddress: CustomStringConvertible {
    public var description: String {
        switch family {
        case .ipv4: IPv4AddressFormatter.format(UInt32(truncatingIfNeeded: value))
        case .ipv6: IPv6AddressFormatter.format(value)
        }
    }
}
