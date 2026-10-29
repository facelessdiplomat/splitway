import Foundation

public struct RuntimeStatistics: Sendable, Hashable, Codable {
    public let peers: [PeerRuntimeStatistics]

    public init(peers: [PeerRuntimeStatistics]) {
        self.peers = peers
    }

    public var receivedByteCount: UInt64 {
        peers.reduce(0) { total, peer in total + peer.receivedByteCount }
    }

    public var transmittedByteCount: UInt64 {
        peers.reduce(0) { total, peer in total + peer.transmittedByteCount }
    }

    public var latestHandshake: Date? {
        peers.compactMap(\.latestHandshake).max()
    }
}
