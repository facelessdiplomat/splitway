struct DNSMessageCursor {
    private static let pointerMask: UInt8 = 0xC0
    private static let pointerByteCount = 2

    private let bytes: [UInt8]
    private var offset: Int

    init(bytes: [UInt8], offset: Int) {
        self.bytes = bytes
        self.offset = offset
    }

    mutating func skipName() throws(DNSReplyError) {
        while true {
            guard offset < bytes.count else { throw .truncated }
            let length = bytes[offset]
            if length == 0 {
                offset += 1
                return
            }
            if length & Self.pointerMask == Self.pointerMask {
                try skip(Self.pointerByteCount)
                return
            }
            try skip(Int(length) + 1)
        }
    }

    mutating func skip(_ count: Int) throws(DNSReplyError) {
        guard offset + count <= bytes.count else { throw .truncated }
        offset += count
    }

    mutating func readUInt16() throws(DNSReplyError) -> UInt16 {
        let pair = try read(2)
        return UInt16(pair[0]) << 8 | UInt16(pair[1])
    }

    mutating func read(_ count: Int) throws(DNSReplyError) -> [UInt8] {
        guard offset + count <= bytes.count else { throw .truncated }
        defer { offset += count }
        return Array(bytes[offset..<offset + count])
    }
}
