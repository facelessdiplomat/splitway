enum IPNetworkParser {
    private static let maximumPrefixLengthDigits = 3

    static func parse(_ text: String) throws(IPNetworkParsingError) -> IPNetwork {
        let components = text.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        let address = try parseAddress(components[0])
        guard components.count > 1 else {
            return IPNetwork(address: address, trustedPrefixLength: address.family.bitWidth)
        }
        return try IPNetwork(address: address, prefixLength: parsePrefixLength(components[1]))
    }

    private static func parseAddress(_ text: Substring) throws(IPNetworkParsingError) -> IPAddress {
        do {
            return try IPAddress(String(text))
        } catch {
            throw .invalidAddress(error)
        }
    }

    private static func parsePrefixLength(_ text: Substring) throws(IPNetworkParsingError) -> Int {
        guard CanonicalDecimalText.isCanonical(text, maximumDigits: maximumPrefixLengthDigits),
            let prefixLength = Int(text)
        else { throw .malformedPrefixLength }
        return prefixLength
    }
}
