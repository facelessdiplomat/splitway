struct DNSMessageReader {
    private static let compressionPointerMarker: UInt8 = 0xC0
    private static let compressionPointerByteCount = 2
    private static let maximumNameByteCount = 255

    private let bytes: [UInt8]
    private(set) var offset: Int

    init(_ bytes: [UInt8], offset: Int) {
        self.bytes = bytes
        self.offset = offset
    }

    mutating func skip(_ byteCount: Int) -> Bool {
        guard byteCount <= bytes.count - offset else { return false }
        offset += byteCount
        return true
    }

    mutating func readUInt16() -> UInt16? {
        guard bytes.count - offset >= 2 else { return nil }
        defer { offset += 2 }
        return UInt16(bytes[offset]) << 8 | UInt16(bytes[offset + 1])
    }

    mutating func readUInt32() -> UInt32? {
        guard bytes.count - offset >= 4, let high = readUInt16(), let low = readUInt16() else { return nil }
        return UInt32(high) << 16 | UInt32(low)
    }

    mutating func skipName() -> Bool {
        var nameByteCount = 0
        while offset < bytes.count {
            let labelLength = bytes[offset]
            if labelLength & Self.compressionPointerMarker == Self.compressionPointerMarker {
                return skip(Self.compressionPointerByteCount)
            }
            guard labelLength & Self.compressionPointerMarker == 0 else { return false }
            nameByteCount += Int(labelLength) + 1
            guard nameByteCount <= Self.maximumNameByteCount, skip(Int(labelLength) + 1) else { return false }
            if labelLength == 0 {
                return true
            }
        }
        return false
    }
}
