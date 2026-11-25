public struct ServiceTint: Sendable, Hashable {
    static let neutral = ServiceTint(red: 0x8E, green: 0x8E, blue: 0x93)

    private static let hexadecimalDigitCount = 6

    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    public init(hexadecimal text: String) throws(ServiceIconError) {
        let digits = text.dropFirst()
        guard text.first == "#", digits.count == Self.hexadecimalDigitCount, digits.allSatisfy(\.isHexDigit),
            let value = UInt32(digits, radix: 16)
        else { throw .malformedTint }
        self.init(
            red: UInt8(truncatingIfNeeded: value >> 16),
            green: UInt8(truncatingIfNeeded: value >> 8),
            blue: UInt8(truncatingIfNeeded: value)
        )
    }

    private init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}
