enum ASCIICharacterClass {
    static func isBase64Alphabet(_ byte: UInt8) -> Bool {
        isLetter(byte) || isDigit(byte) || byte == UInt8(ascii: "+") || byte == UInt8(ascii: "/")
    }

    static func isBase64AlphabetOrPadding(_ byte: UInt8) -> Bool {
        isBase64Alphabet(byte) || byte == UInt8(ascii: "=")
    }

    static func isHexDigit(_ byte: UInt8) -> Bool {
        isDigit(byte) || (UInt8(ascii: "a")...UInt8(ascii: "f")).contains(lowercased(byte))
    }

    static func isSpaceOrTab(_ byte: UInt8) -> Bool {
        byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\t")
    }

    static func isWhitespace(_ byte: UInt8) -> Bool {
        isSpaceOrTab(byte) || byte == UInt8(ascii: "\n") || byte == UInt8(ascii: "\r")
    }

    static func lowercased(_ byte: UInt8) -> UInt8 {
        isUppercaseLetter(byte) ? byte + (UInt8(ascii: "a") - UInt8(ascii: "A")) : byte
    }

    private static func isLetter(_ byte: UInt8) -> Bool {
        isUppercaseLetter(byte) || (UInt8(ascii: "a")...UInt8(ascii: "z")).contains(byte)
    }

    private static func isUppercaseLetter(_ byte: UInt8) -> Bool {
        (UInt8(ascii: "A")...UInt8(ascii: "Z")).contains(byte)
    }

    private static func isDigit(_ byte: UInt8) -> Bool {
        (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte)
    }
}
