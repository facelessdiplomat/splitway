enum IPv6AddressFormatter {
    private static let groupCount = 8
    private static let bitsPerGroup = 16
    private static let minimumCompressedRunLength = 2
    private static let ipv4MappedPrefix: UInt128 = 0xFFFF << 32
    private static let ipv4MappedPrefixMask: UInt128 = ~UInt128(UInt32.max)

    static func format(_ value: UInt128) -> String {
        if value & ipv4MappedPrefixMask == ipv4MappedPrefix {
            return "::ffff:" + IPv4AddressFormatter.format(UInt32(truncatingIfNeeded: value))
        }
        let groups = (0..<groupCount).map { index in
            UInt16(truncatingIfNeeded: value >> (bitsPerGroup * (groupCount - 1 - index)))
        }
        guard let zeroRun = longestZeroRun(in: groups) else {
            return hexadecimal(groups[...])
        }
        return hexadecimal(groups[..<zeroRun.lowerBound]) + "::" + hexadecimal(groups[zeroRun.upperBound...])
    }

    private static func hexadecimal(_ groups: ArraySlice<UInt16>) -> String {
        groups.map { group in String(group, radix: 16) }.joined(separator: ":")
    }

    private static func longestZeroRun(in groups: [UInt16]) -> Range<Int>? {
        var longestRun: Range<Int>?
        var currentRunStart: Int?
        for index in groups.indices {
            guard groups[index] == 0 else {
                currentRunStart = nil
                continue
            }
            let runStart = currentRunStart ?? index
            currentRunStart = runStart
            let run = runStart..<(index + 1)
            if run.count >= minimumCompressedRunLength, run.count > (longestRun?.count ?? 0) {
                longestRun = run
            }
        }
        return longestRun
    }
}
