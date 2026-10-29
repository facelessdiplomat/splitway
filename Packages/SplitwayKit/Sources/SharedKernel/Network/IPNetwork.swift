public struct IPNetwork: Sendable, Hashable {
    public let address: IPAddress
    public let prefixLength: Int

    public init(address: IPAddress, prefixLength: Int) throws(IPNetworkParsingError) {
        guard (0...address.family.bitWidth).contains(prefixLength) else { throw .prefixLengthOutOfRange }
        self.init(address: address, trustedPrefixLength: prefixLength)
    }

    public init(_ text: String) throws(IPNetworkParsingError) {
        self = try IPNetworkParser.parse(text)
    }

    init(address: IPAddress, trustedPrefixLength: Int) {
        self.address = address
        self.prefixLength = trustedPrefixLength
    }

    public var family: IPAddressFamily {
        address.family
    }

    public var firstAddress: IPAddress {
        IPAddress(family: family, value: address.value & family.networkMask(prefixLength: prefixLength))
    }

    public var lastAddress: IPAddress {
        IPAddress(family: family, value: address.value | family.hostMask(prefixLength: prefixLength))
    }

    public var normalized: IPNetwork {
        IPNetwork(address: firstAddress, trustedPrefixLength: prefixLength)
    }

    public var hasHostBits: Bool {
        address != firstAddress
    }

    public func contains(_ candidate: IPAddress) -> Bool {
        let mask = family.networkMask(prefixLength: prefixLength)
        return candidate.family == family && candidate.value & mask == address.value & mask
    }

    public func contains(_ network: IPNetwork) -> Bool {
        network.prefixLength >= prefixLength && contains(network.address)
    }

    public func overlaps(_ network: IPNetwork) -> Bool {
        contains(network) || network.contains(self)
    }

    var addressRange: ClosedRange<UInt128> {
        firstAddress.value...lastAddress.value
    }
}
