import Foundation
import TunnelConfiguration
import TunnelEngine

public struct PeerStatisticsRow: Identifiable, Sendable, Hashable {
    public let publicKey: String
    public let endpoint: String?
    public let activity: PeerActivity?

    public var id: String {
        publicKey
    }

    init(peer: PeerConfiguration, statistics: PeerRuntimeStatistics?, now: Date) {
        publicKey = peer.publicKey.base64EncodedText
        endpoint = peer.endpoint?.description
        activity = statistics.map { statistics in
            PeerActivity(
                latestHandshake: HandshakeRecency(latestHandshake: statistics.latestHandshake, now: now),
                receivedByteCount: statistics.receivedByteCount,
                transmittedByteCount: statistics.transmittedByteCount
            )
        }
    }
}
