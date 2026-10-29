public struct PeerActivity: Sendable, Hashable {
    public let latestHandshake: HandshakeRecency
    public let receivedByteCount: UInt64
    public let transmittedByteCount: UInt64
}
