enum ASCIIByte {
    static let zero = UInt8(ascii: "0")

    private static let asciiUpperBound: UInt8 = 0x80
    private static let hyphen = UInt8(ascii: "-")
    private static let decimalDigits = UInt8(ascii: "0")...UInt8(ascii: "9")
    private static let lowercaseLetters = UInt8(ascii: "a")...UInt8(ascii: "z")
    private static let uppercaseLetters = UInt8(ascii: "A")...UInt8(ascii: "Z")
    private static let lowercaseHexadecimalLetters = UInt8(ascii: "a")...UInt8(ascii: "f")
    private static let uppercaseHexadecimalLetters = UInt8(ascii: "A")...UInt8(ascii: "F")

    static func isASCII(_ byte: UInt8) -> Bool {
        byte < asciiUpperBound
    }

    static func isDecimalDigit(_ byte: UInt8) -> Bool {
        decimalDigits.contains(byte)
    }

    static func isHexadecimalDigit(_ byte: UInt8) -> Bool {
        decimalDigits.contains(byte)
            || lowercaseHexadecimalLetters.contains(byte)
            || uppercaseHexadecimalLetters.contains(byte)
    }

    static func isHostnameCharacter(_ byte: UInt8) -> Bool {
        decimalDigits.contains(byte)
            || lowercaseLetters.contains(byte)
            || uppercaseLetters.contains(byte)
            || byte == hyphen
    }
}
