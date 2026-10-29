import Foundation
import TunnelConfiguration

struct PeerStatisticsAccumulator {
    private static let nanosecondsPerSecond: TimeInterval = 1_000_000_000

    private let publicKey: PublicKey
    private var receivedByteCount: UInt64 = 0
    private var transmittedByteCount: UInt64 = 0
    private var handshakeSeconds: Int64 = 0
    private var handshakeNanoseconds: Int64 = 0

    init(publicKey: PublicKey) {
        self.publicKey = publicKey
    }

    mutating func record(key: Substring, value: Substring) throws(UAPIResponseError) {
        switch key {
        case "rx_bytes": receivedByteCount = try UAPIValue.number(value)
        case "tx_bytes": transmittedByteCount = try UAPIValue.number(value)
        case "last_handshake_time_sec": handshakeSeconds = try UAPIValue.number(value)
        case "last_handshake_time_nsec": handshakeNanoseconds = try UAPIValue.number(value)
        default: break
        }
    }

    var statistics: PeerRuntimeStatistics {
        PeerRuntimeStatistics(
            publicKey: publicKey,
            receivedByteCount: receivedByteCount,
            transmittedByteCount: transmittedByteCount,
            latestHandshake: latestHandshake
        )
    }

    private var latestHandshake: Date? {
        guard handshakeSeconds != 0 || handshakeNanoseconds != 0 else { return nil }
        let secondsSince1970 =
            TimeInterval(handshakeSeconds) + TimeInterval(handshakeNanoseconds) / Self.nanosecondsPerSecond
        return Date(timeIntervalSince1970: secondsSince1970)
    }
}
