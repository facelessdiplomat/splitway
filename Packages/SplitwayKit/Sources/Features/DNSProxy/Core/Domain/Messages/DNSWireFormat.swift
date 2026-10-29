enum DNSWireFormat {
    static let headerByteCount = 12
    static let identifierRange = 0..<2
    static let firstFlagsOffset = 2
    static let secondFlagsOffset = 3
    static let questionCountRange = 4..<6
    static let questionCountOffset = 4
    static let answerCountOffset = 6
    static let authorityCountOffset = 8
    static let additionalCountOffset = 10
    static let questionFieldsByteCount = 4
    static let recordClassByteCount = 2
    static let queryResponseFlag: UInt8 = 0x80
    static let optionRecordType: UInt16 = 41
    static let dnssecOKFlag: UInt16 = 0x8000

    static func bytes(of value: UInt16) -> [UInt8] {
        [UInt8(value >> 8), UInt8(truncatingIfNeeded: value)]
    }

    static func count(at offset: Int, in message: [UInt8]) -> Int {
        Int(message[offset]) << 8 | Int(message[offset + 1])
    }
}
