extension IPNetwork {
    public var halves: [IPNetwork] {
        guard prefixLength < family.bitWidth else { return [] }
        let halfPrefixLength = prefixLength + 1
        let upperHalfBit = UInt128(1) << (family.bitWidth - halfPrefixLength)
        return [
            IPNetwork(address: firstAddress, trustedPrefixLength: halfPrefixLength),
            IPNetwork(
                address: IPAddress(family: family, value: firstAddress.value | upperHalfBit),
                trustedPrefixLength: halfPrefixLength
            ),
        ]
    }

    public func address(atOffset offset: Int) -> IPAddress? {
        let hostBitCount = family.bitWidth - prefixLength
        let fitsInNetwork = hostBitCount >= UInt128.bitWidth || UInt128(offset) < UInt128(1) << hostBitCount
        guard offset >= 0, fitsInNetwork else { return nil }
        return IPAddress(family: family, value: firstAddress.value + UInt128(offset))
    }
}
