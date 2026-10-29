enum IPAddressParser {
    static func parse(_ text: String) throws(IPAddressParsingError) -> IPAddress {
        guard !text.isEmpty else { throw .empty }
        guard !text.contains("%") else { throw .zoneIdentifierNotSupported }
        if text.contains(":") {
            guard let value = IPv6AddressParser.parse(text[...]) else { throw .malformedIPv6 }
            return .ipv6(value)
        }
        guard let value = IPv4AddressParser.parse(text[...]) else { throw .malformedIPv4 }
        return .ipv4(value)
    }
}
