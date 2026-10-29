enum CIDRDecomposition {
    static func networks(covering range: ClosedRange<UInt128>, in family: IPAddressFamily) -> [IPNetwork] {
        var networks: [IPNetwork] = []
        var blockStart = range.lowerBound
        while true {
            let prefixLength =
                family.bitWidth - largestBlockBitCount(from: blockStart, through: range.upperBound, in: family)
            networks.append(
                IPNetwork(address: IPAddress(family: family, value: blockStart), trustedPrefixLength: prefixLength)
            )
            let blockEnd = blockStart + family.hostMask(prefixLength: prefixLength)
            guard blockEnd < range.upperBound else { return networks }
            blockStart = blockEnd + 1
        }
    }

    private static func largestBlockBitCount(
        from start: UInt128,
        through end: UInt128,
        in family: IPAddressFamily
    ) -> Int {
        let alignmentBitCount = min(start.trailingZeroBitCount, family.bitWidth)
        let span = end - start
        let fittingBitCount = span == .max ? UInt128.bitWidth : UInt128.bitWidth - 1 - (span + 1).leadingZeroBitCount
        return min(alignmentBitCount, fittingBitCount)
    }
}
