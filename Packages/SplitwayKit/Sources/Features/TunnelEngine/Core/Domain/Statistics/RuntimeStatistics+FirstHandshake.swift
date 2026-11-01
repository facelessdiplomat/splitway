extension RuntimeStatistics {
    private static let handshakeInitiationByteCount: UInt64 = 148
    private static let unansweredInitiationsBeforeWarning: UInt64 = 3

    public var hasUnansweredFirstHandshake: Bool {
        let unansweredByteCount = Self.handshakeInitiationByteCount * Self.unansweredInitiationsBeforeWarning
        return latestHandshake == nil && peers.contains { peer in peer.transmittedByteCount >= unansweredByteCount }
    }
}
