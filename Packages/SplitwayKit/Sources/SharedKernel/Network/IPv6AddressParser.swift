enum IPv6AddressParser {
    private static let groupCount = 8
    private static let maximumGroupDigits = 4
    private static let bitsPerGroup = 16
    private static let compressionMarker = "::"

    static func parse(_ text: Substring) -> UInt128? {
        let compressions = text.ranges(of: compressionMarker)
        switch compressions.count {
        case 0:
            guard let groups = parseGroups(text, allowsEmbeddedIPv4: true), groups.count == groupCount else {
                return nil
            }
            return combine(groups)
        case 1:
            return parseCompressed(text, around: compressions[0])
        default:
            return nil
        }
    }

    private static func parseCompressed(_ text: Substring, around compression: Range<Substring.Index>) -> UInt128? {
        let head = text[..<compression.lowerBound]
        let tail = text[compression.upperBound...]
        guard let headGroups = head.isEmpty ? [] : parseGroups(head, allowsEmbeddedIPv4: false),
            let tailGroups = tail.isEmpty ? [] : parseGroups(tail, allowsEmbeddedIPv4: true),
            headGroups.count + tailGroups.count < groupCount
        else { return nil }
        let compressedZeros = [UInt16](repeating: 0, count: groupCount - headGroups.count - tailGroups.count)
        return combine(headGroups + compressedZeros + tailGroups)
    }

    private static func parseGroups(_ text: Substring, allowsEmbeddedIPv4: Bool) -> [UInt16]? {
        var parts = text.split(separator: ":", omittingEmptySubsequences: false)
        var embeddedIPv4Groups: [UInt16] = []
        if allowsEmbeddedIPv4, let lastPart = parts.last, lastPart.contains(".") {
            guard let embeddedIPv4 = IPv4AddressParser.parse(lastPart) else { return nil }
            embeddedIPv4Groups = [
                UInt16(truncatingIfNeeded: embeddedIPv4 >> bitsPerGroup), UInt16(truncatingIfNeeded: embeddedIPv4),
            ]
            parts.removeLast()
        }
        var groups: [UInt16] = []
        for part in parts {
            guard let group = parseGroup(part) else { return nil }
            groups.append(group)
        }
        return groups + embeddedIPv4Groups
    }

    private static func parseGroup(_ group: Substring) -> UInt16? {
        guard (1...maximumGroupDigits).contains(group.utf8.count), group.utf8.allSatisfy(ASCIIByte.isHexadecimalDigit)
        else { return nil }
        return UInt16(group, radix: 16)
    }

    private static func combine(_ groups: [UInt16]) -> UInt128 {
        groups.reduce(UInt128(0)) { address, group in address << bitsPerGroup | UInt128(group) }
    }
}
