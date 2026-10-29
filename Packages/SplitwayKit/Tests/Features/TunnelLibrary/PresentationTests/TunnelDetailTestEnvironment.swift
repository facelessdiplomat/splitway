import Foundation
import ProviderMessaging
import SharedKernelTestSupport
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelConnection
import TunnelEngine
import TunnelLibrary
import TunnelLibraryPresentation

@MainActor
struct TunnelDetailTestEnvironment {
    static let now = Date(timeIntervalSince1970: 1_793_268_900)

    let messenger: RecordingStatisticsMessenger
    let ticker = ManualTicker()
    let model: TunnelDetailModel

    init(outcome: Result<ProviderResponse, ProviderMessagingError>) throws {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.multiplePeers).configuration)
        messenger = RecordingStatisticsMessenger(outcome: outcome)
        model = TunnelDetailModel(
            tunnel: Tunnel(name: try TunnelName("Office"), configuration: configuration),
            polling: TunnelStatisticsPolling(
                fetchStatistics: FetchRuntimeStatisticsUseCase(messenger: messenger),
                clock: FixedWallClock(Self.now),
                ticker: ticker
            )
        )
    }

    init(reporting peers: [PeerRuntimeStatistics] = []) throws {
        try self.init(outcome: .success(.runtimeStatistics(statistics: RuntimeStatistics(peers: peers))))
    }

    static func firstPeer(handshakeSecondsAgo: TimeInterval?, received: UInt64 = 0, sent: UInt64 = 0) throws
        -> PeerRuntimeStatistics
    {
        PeerRuntimeStatistics(
            publicKey: try SampleKeys.firstPeerPublicKey(),
            receivedByteCount: received,
            transmittedByteCount: sent,
            latestHandshake: handshakeSecondsAgo.map { seconds in now.addingTimeInterval(-seconds) }
        )
    }

    static func secondPeerWithoutHandshake() throws -> PeerRuntimeStatistics {
        PeerRuntimeStatistics(
            publicKey: try SampleKeys.secondPeerPublicKey(),
            receivedByteCount: 0,
            transmittedByteCount: 0,
            latestHandshake: nil
        )
    }
}
