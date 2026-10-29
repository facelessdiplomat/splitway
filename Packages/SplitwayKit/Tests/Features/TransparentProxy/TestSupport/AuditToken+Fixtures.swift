import TransparentProxy

extension AuditToken {
    private static let userIdentifierWord: [UInt8] = [0xF5, 0x01, 0x00, 0x00]
    private static let groupIdentifierWord: [UInt8] = [0x14, 0x00, 0x00, 0x00]
    private static let sessionIdentifierWord: [UInt8] = [0xA8, 0x86, 0x01, 0x00]

    public static func fixture(processIdentifier: Int32, version: UInt32) throws -> AuditToken {
        let words = [
            userIdentifierWord, userIdentifierWord, groupIdentifierWord, userIdentifierWord, groupIdentifierWord,
            littleEndianBytes(of: UInt32(bitPattern: processIdentifier)), sessionIdentifierWord,
            littleEndianBytes(of: version),
        ]
        return try AuditToken(bytes: words.flatMap(\.self))
    }

    private static func littleEndianBytes(of word: UInt32) -> [UInt8] {
        (0..<4).map { index in UInt8(truncatingIfNeeded: word >> (8 * index)) }
    }
}
