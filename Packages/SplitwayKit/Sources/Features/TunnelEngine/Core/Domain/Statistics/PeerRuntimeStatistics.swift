import Foundation
import TunnelConfiguration

public struct PeerRuntimeStatistics: Sendable, Hashable {
    public let publicKey: PublicKey
    public let receivedByteCount: UInt64
    public let transmittedByteCount: UInt64
    public let latestHandshake: Date?

    public init(publicKey: PublicKey, receivedByteCount: UInt64, transmittedByteCount: UInt64, latestHandshake: Date?) {
        self.publicKey = publicKey
        self.receivedByteCount = receivedByteCount
        self.transmittedByteCount = transmittedByteCount
        self.latestHandshake = latestHandshake
    }
}
