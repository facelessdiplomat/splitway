enum IPv4AddressParser {
    private static let octetCount = 4
    private static let maximumOctetDigits = 3
    private static let bitsPerOctet = 8

    static func parse(_ text: Substring) -> UInt32? {
        let octets = text.split(separator: ".", omittingEmptySubsequences: false)
        guard octets.count == octetCount else { return nil }
        var address: UInt32 = 0
        for octet in octets {
            guard let octetValue = parseOctet(octet) else { return nil }
            address = address << bitsPerOctet | UInt32(octetValue)
        }
        return address
    }

    private static func parseOctet(_ octet: Substring) -> UInt8? {
        guard CanonicalDecimalText.isCanonical(octet, maximumDigits: maximumOctetDigits) else { return nil }
        return UInt8(octet)
    }
}
