public struct UDPRelayPolicy: Sendable, Hashable {
    public static let largestDatagramByteCount = 65_535
    public static let standard = UDPRelayPolicy(
        trustedDatagramBufferByteCount: largestDatagramByteCount,
        idleTimeout: .seconds(5 * 60),
        maximumAssociations: 256
    )

    public let datagramBufferByteCount: Int
    public let idleTimeout: Duration
    public let maximumAssociations: Int

    public init(
        datagramBufferByteCount: Int,
        idleTimeout: Duration,
        maximumAssociations: Int
    ) throws(RelayPolicyError) {
        guard (1...Self.largestDatagramByteCount).contains(datagramBufferByteCount) else {
            throw .bufferSizeOutOfRange
        }
        guard idleTimeout > .zero else { throw .nonPositiveTimeout }
        guard maximumAssociations > 0 else { throw .nonPositiveAssociationLimit }
        self.init(
            trustedDatagramBufferByteCount: datagramBufferByteCount,
            idleTimeout: idleTimeout,
            maximumAssociations: maximumAssociations
        )
    }

    private init(trustedDatagramBufferByteCount: Int, idleTimeout: Duration, maximumAssociations: Int) {
        datagramBufferByteCount = trustedDatagramBufferByteCount
        self.idleTimeout = idleTimeout
        self.maximumAssociations = maximumAssociations
    }
}
