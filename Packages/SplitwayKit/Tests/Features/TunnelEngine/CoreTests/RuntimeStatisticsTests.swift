import Foundation
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEngine

@Suite
struct RuntimeStatisticsTests {
    @Test(arguments: [(UInt64(444), true), (443, false), (148, false), (0, false)])
    func reportsAFirstHandshakeUnansweredAfterThreeInitiations(sentByteCount: UInt64, isUnanswered: Bool) throws {
        let statistics = RuntimeStatistics(peers: [try Self.firstPeer(sentByteCount: sentByteCount)])

        #expect(statistics.hasUnansweredFirstHandshake == isUnanswered)
    }

    @Test
    func trustsATunnelOnceAnyPeerHasShakenHands() throws {
        let statistics = RuntimeStatistics(peers: [
            try Self.firstPeer(sentByteCount: 1_480),
            PeerRuntimeStatistics(
                publicKey: try SampleKeys.secondPeerPublicKey(),
                receivedByteCount: 92,
                transmittedByteCount: 148,
                latestHandshake: Date(timeIntervalSince1970: 1_793_268_900)
            ),
        ])

        #expect(!statistics.hasUnansweredFirstHandshake)
    }

    private static func firstPeer(sentByteCount: UInt64) throws -> PeerRuntimeStatistics {
        PeerRuntimeStatistics(
            publicKey: try SampleKeys.firstPeerPublicKey(),
            receivedByteCount: 0,
            transmittedByteCount: sentByteCount,
            latestHandshake: nil
        )
    }
}
