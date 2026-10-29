public struct IPAddress: Sendable, Hashable {
    public let family: IPAddressFamily
    let value: UInt128

    init(family: IPAddressFamily, value: UInt128) {
        self.family = family
        self.value = value & family.allAddressBits
    }

    public init(_ text: String) throws(IPAddressParsingError) {
        self = try IPAddressParser.parse(text)
    }

    public static func ipv4(_ value: UInt32) -> IPAddress {
        IPAddress(family: .ipv4, value: UInt128(value))
    }

    public static func ipv6(_ value: UInt128) -> IPAddress {
        IPAddress(family: .ipv6, value: value)
    }
}
