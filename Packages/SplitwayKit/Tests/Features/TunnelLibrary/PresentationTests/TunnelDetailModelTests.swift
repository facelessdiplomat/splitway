import Testing
import TunnelConfigurationTestSupport
import TunnelLibraryPresentation

@MainActor
@Suite
struct TunnelDetailModelTests {
    @Test
    func listsConfiguredPeersBeforeStatisticsArrive() throws {
        let environment = try TunnelDetailTestEnvironment()

        #expect(
            environment.model.peers.map(\.publicKey)
                == [SampleKeys.firstPeerPublicKeyText, SampleKeys.secondPeerPublicKeyText]
        )
        #expect(environment.model.peers.map(\.endpoint) == ["203.0.113.10:51820", "203.0.113.20:51820"])
        #expect(environment.model.peers.map(\.activity) == [nil, nil])
    }

    @Test
    func tellsHowLongAgoEachPeerShookHands() async throws {
        let environment = try TunnelDetailTestEnvironment(reporting: [
            try TunnelDetailTestEnvironment.firstPeer(handshakeSecondsAgo: 125.7),
            try TunnelDetailTestEnvironment.secondPeerWithoutHandshake(),
        ])

        await environment.model.refreshStatistics()

        #expect(environment.model.peers.map(\.activity?.latestHandshake) == [.elapsed(.seconds(125)), .never])
    }

    @Test
    func neverReportsAHandshakeFromTheFuture() async throws {
        let environment = try TunnelDetailTestEnvironment(reporting: [
            try TunnelDetailTestEnvironment.firstPeer(handshakeSecondsAgo: -30)
        ])

        await environment.model.refreshStatistics()

        #expect(environment.model.peers.first?.activity?.latestHandshake == .elapsed(.zero))
    }

    @Test
    func showsTrafficOfEachPeer() async throws {
        let environment = try TunnelDetailTestEnvironment(reporting: [
            try TunnelDetailTestEnvironment.firstPeer(handshakeSecondsAgo: 5, received: 2_048, sent: 1_024)
        ])

        await environment.model.refreshStatistics()

        #expect(environment.model.peers.first?.activity?.receivedByteCount == 2_048)
        #expect(environment.model.peers.first?.activity?.transmittedByteCount == 1_024)
        #expect(environment.model.peers.last?.activity == nil)
    }

    @Test
    func explainsWhyStatisticsAreUnavailable() async throws {
        let environment = try TunnelDetailTestEnvironment(outcome: .success(.failure(reason: .tunnelNotRunning)))

        await environment.model.refreshStatistics()

        #expect(environment.model.statisticsProblem == .tunnelNotRunning)
        #expect(environment.model.peers.map(\.activity) == [nil, nil])
    }

    @Test
    func pollsUntilTheScreenGoesAway() async throws {
        let environment = try TunnelDetailTestEnvironment()
        let tracking = Task { await environment.model.trackStatistics(isTunnelRunning: true) }
        await environment.ticker.waitUntilTicking()

        environment.ticker.tick()
        environment.ticker.tick()
        await environment.messenger.waitForRequests(2)
        tracking.cancel()
        await tracking.value

        #expect(!environment.ticker.isTicking)
    }

    @Test
    func doesNotPollADisconnectedTunnel() async throws {
        let environment = try TunnelDetailTestEnvironment(reporting: [
            try TunnelDetailTestEnvironment.firstPeer(handshakeSecondsAgo: 5)
        ])
        await environment.model.refreshStatistics()

        await environment.model.trackStatistics(isTunnelRunning: false)

        #expect(await environment.messenger.requestCount == 1)
        #expect(!environment.ticker.isTicking)
        #expect(environment.model.peers.map(\.activity) == [nil, nil])
    }

    @Test
    func ignoresAReplyThatArrivesAfterPollingStopped() async throws {
        let environment = try TunnelDetailTestEnvironment(reporting: [
            try TunnelDetailTestEnvironment.firstPeer(handshakeSecondsAgo: 5)
        ])
        await environment.messenger.holdNextResponse()
        let tracking = Task { await environment.model.trackStatistics(isTunnelRunning: true) }
        await environment.ticker.waitUntilTicking()

        environment.ticker.tick()
        await environment.messenger.waitUntilResponseIsHeld()
        tracking.cancel()
        await environment.messenger.releaseHeldResponse()
        await tracking.value

        #expect(environment.model.peers.map(\.activity) == [nil, nil])
    }
}
