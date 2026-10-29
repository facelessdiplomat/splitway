public enum IPAddressFamily: Sendable, Hashable, Comparable, CaseIterable {
    case ipv4
    case ipv6

    public var bitWidth: Int {
        switch self {
        case .ipv4: 32
        case .ipv6: 128
        }
    }

    var allAddressBits: UInt128 {
        switch self {
        case .ipv4: UInt128(UInt32.max)
        case .ipv6: UInt128.max
        }
    }
}
