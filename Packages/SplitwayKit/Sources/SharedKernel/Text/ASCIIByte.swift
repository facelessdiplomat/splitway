enum ASCIIByte {
    static let zero = UInt8(ascii: "0")

    private static let decimalDigits = UInt8(ascii: "0")...UInt8(ascii: "9")
    private static let lowercaseHexadecimalLetters = UInt8(ascii: "a")...UInt8(ascii: "f")
    private static let uppercaseHexadecimalLetters = UInt8(ascii: "A")...UInt8(ascii: "F")

    static func isDecimalDigit(_ byte: UInt8) -> Bool {
        decimalDigits.contains(byte)
    }

    static func isHexadecimalDigit(_ byte: UInt8) -> Bool {
        decimalDigits.contains(byte)
            || lowercaseHexadecimalLetters.contains(byte)
            || uppercaseHexadecimalLetters.contains(byte)
    }
}
