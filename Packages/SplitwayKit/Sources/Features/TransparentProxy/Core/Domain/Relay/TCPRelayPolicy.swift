public struct TCPRelayPolicy: Sendable, Hashable {
    public static let standard = TCPRelayPolicy(
        trustedChunkByteCount: 64 * 1024,
        connectTimeout: .seconds(30),
        idleTimeout: .seconds(2 * 60 * 60 + 4 * 60)
    )

    public let chunkByteCount: Int
    public let connectTimeout: Duration
    public let idleTimeout: Duration

    public init(chunkByteCount: Int, connectTimeout: Duration, idleTimeout: Duration) throws(RelayPolicyError) {
        guard chunkByteCount > 0 else { throw .bufferSizeOutOfRange }
        guard connectTimeout > .zero, idleTimeout > .zero else { throw .nonPositiveTimeout }
        self.init(trustedChunkByteCount: chunkByteCount, connectTimeout: connectTimeout, idleTimeout: idleTimeout)
    }

    private init(trustedChunkByteCount: Int, connectTimeout: Duration, idleTimeout: Duration) {
        chunkByteCount = trustedChunkByteCount
        self.connectTimeout = connectTimeout
        self.idleTimeout = idleTimeout
    }
}
