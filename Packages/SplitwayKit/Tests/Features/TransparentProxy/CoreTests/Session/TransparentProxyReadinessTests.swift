import AppRouting
import Foundation
import Testing
import TransparentProxy
import TransparentProxyTestSupport
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEngine

@Suite
struct TransparentProxyReadinessTests {
    @Test
    func addsAKeepaliveToKeepTheHandshakeFresh() async throws {
        let environment = TransparentProxyTestEnvironment()

        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )

        let applied = environment.engine.network.state.current.appliedConfigurations.map(\.text)
        #expect(applied.contains { text in text.contains("persistent_keepalive_interval=25") })
    }

    @Test
    func blocksSelectedFlowsOnceTheHandshakeIsStale() async throws {
        let environment = try await Self.startedEnvironment(whenTunnelUnavailable: .block)
        try Self.recordHandshake(at: environment.clock.now(), in: environment)
        let flow = ScriptedStreamFlow()

        environment.session.maintain(at: environment.clock.now().addingTimeInterval(181))
        let isHandled = environment.session.handleStream(flow, request: try Self.browserRequest())

        #expect(isHandled)
        #expect(flow.state.current.readClosings == [.refused])
        #expect(environment.engine.network.state.update { snapshot in snapshot.connections.isEmpty })
    }

    @Test
    func letsSelectedFlowsGoDirectWhenBypassIsChosen() async throws {
        let environment = try await Self.startedEnvironment(whenTunnelUnavailable: .bypass)

        environment.session.maintain(at: environment.clock.now().addingTimeInterval(16))
        let isHandled = environment.session.handleStream(ScriptedStreamFlow(), request: try Self.browserRequest())

        #expect(!isHandled)
    }

    @Test
    func readiesTheTunnelAgainAfterAFreshHandshake() async throws {
        let environment = try await Self.startedEnvironment(whenTunnelUnavailable: .block)
        let later = environment.clock.now().addingTimeInterval(400)
        environment.session.maintain(at: later)
        try Self.recordHandshake(at: later, in: environment)

        environment.session.maintain(at: later)
        let isHandled = environment.session.handleStream(ScriptedStreamFlow(), request: try Self.browserRequest())

        #expect(isHandled)
        await environment.engine.network.state.wait { snapshot in snapshot.connections.count == 1 }
    }

    @Test
    func closesIdleRelaysOnEveryTick() async throws {
        let environment = try await Self.startedEnvironment(whenTunnelUnavailable: .block)
        let flow = ScriptedStreamFlow()
        _ = environment.session.handleStream(flow, request: try Self.browserRequest())
        await flow.state.wait { snapshot in snapshot.isOpened }
        await environment.ticker.waitUntilTicking()

        environment.clock.advance(by: RelayPolicy.standard.tcp.idleTimeout)
        environment.ticker.tick()

        await flow.state.wait { snapshot in !snapshot.readClosings.isEmpty }
    }

    private static func startedEnvironment(
        whenTunnelUnavailable behavior: TunnelUnavailableBehavior
    ) async throws -> TransparentProxyTestEnvironment {
        let environment = TransparentProxyTestEnvironment()
        let policy = RoutingPolicy(
            mode: try TransparentProxyTestEnvironment.selectedBrowser(), whenTunnelUnavailable: behavior)
        _ = try await environment.session.start(TransparentProxyTestEnvironment.tunnel(policy: policy))
        return environment
    }

    private static func recordHandshake(at moment: Date, in environment: TransparentProxyTestEnvironment) throws {
        let statistics = RuntimeStatistics(peers: [
            PeerRuntimeStatistics(
                publicKey: try SampleKeys.firstPeerPublicKey(),
                receivedByteCount: 0,
                transmittedByteCount: 0,
                latestHandshake: moment
            )
        ])
        environment.engine.network.state.update { snapshot in snapshot.statistics = statistics }
    }

    private static func browserRequest() throws -> ProxiedFlowRequest {
        try TransparentProxyTestEnvironment.request(from: TransparentProxyTestEnvironment.browserProcess)
    }
}
