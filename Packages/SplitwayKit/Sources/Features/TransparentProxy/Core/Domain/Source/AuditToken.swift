public struct AuditToken: Sendable, Hashable {
    public static let byteCount = 32
    private static let wordByteCount = 4
    private static let processIdentifierWordIndex = 5
    private static let processVersionWordIndex = 7

    public let bytes: [UInt8]
    public let processInstance: ProcessInstance

    public init(bytes: [UInt8]) throws(AuditTokenError) {
        guard bytes.count == Self.byteCount else { throw .wrongByteCount }
        self.bytes = bytes
        processInstance = ProcessInstance(
            identifier: Int32(bitPattern: Self.word(at: Self.processIdentifierWordIndex, in: bytes)),
            version: Self.word(at: Self.processVersionWordIndex, in: bytes)
        )
    }

    private static func word(at index: Int, in bytes: [UInt8]) -> UInt32 {
        let start = index * wordByteCount
        return bytes[start..<start + wordByteCount].reversed().reduce(0) { word, byte in word << 8 | UInt32(byte) }
    }
}
