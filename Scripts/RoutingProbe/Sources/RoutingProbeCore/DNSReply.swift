public struct DNSReply: Sendable, Hashable {
    private static let headerByteCount = 12
    private static let queryResponseFlag: UInt8 = 0x80
    private static let responseCodeMask: UInt8 = 0x0F
    private static let addressType: UInt16 = 1
    private static let addressByteCount = 4
    private static let questionTypeAndClassByteCount = 4
    private static let classAndTimeToLiveByteCount = 6

    public let identifier: UInt16
    public let responseCode: DNSResponseCode
    public let addresses: [String]

    public init(parsing bytes: [UInt8]) throws(DNSReplyError) {
        guard bytes.count >= Self.headerByteCount else { throw .truncated }
        guard bytes[2] & Self.queryResponseFlag != 0 else { throw .notAReply }
        identifier = Self.value(at: 0, in: bytes)
        responseCode = DNSResponseCode(bytes[3] & Self.responseCodeMask)
        var cursor = DNSMessageCursor(bytes: bytes, offset: Self.headerByteCount)
        for _ in 0..<Self.value(at: 4, in: bytes) {
            try cursor.skipName()
            try cursor.skip(Self.questionTypeAndClassByteCount)
        }
        var addresses: [String] = []
        for _ in 0..<Self.value(at: 6, in: bytes) {
            try cursor.skipName()
            let type = try cursor.readUInt16()
            try cursor.skip(Self.classAndTimeToLiveByteCount)
            let data = try cursor.read(Int(try cursor.readUInt16()))
            if type == Self.addressType, data.count == Self.addressByteCount {
                addresses.append(data.map(String.init).joined(separator: "."))
            }
        }
        self.addresses = addresses
    }

    private static func value(at offset: Int, in bytes: [UInt8]) -> UInt16 {
        UInt16(bytes[offset]) << 8 | UInt16(bytes[offset + 1])
    }
}
