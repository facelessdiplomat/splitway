import AppRouting
import Foundation
import ProviderMessaging
import Testing
import TransparentProxy
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEngine

@Suite
struct TransparentProxyMessageHandlerTests {
    @Test
    func appliesARoutingPolicyOfSelectedApplications() async throws {
        let environment = try await Self.startedEnvironment()
        let handler = TransparentProxyMessageHandler(session: environment.session)
        let policy = RoutingPolicy(mode: try TransparentProxyTestEnvironment.selectedMail())

        let response = await handler.handle(.applyRoutingPolicy(policy: policy))

        #expect(response == .routingPolicyApplied)
    }

    @Test
    func rejectsARoutingPolicyOfAnotherMode() async throws {
        let environment = try await Self.startedEnvironment()
        let handler = TransparentProxyMessageHandler(session: environment.session)

        let response = await handler.handle(.applyRoutingPolicy(policy: RoutingPolicy(mode: .allTraffic)))

        #expect(response == .failure(reason: .routingPolicyRejected))
    }

    @Test
    func reportsTheStatisticsAndHealthOfTheRunningTunnel() async throws {
        let environment = try await Self.startedEnvironment()
        let handler = TransparentProxyMessageHandler(session: environment.session)
        let statistics = RuntimeStatistics(peers: [
            PeerRuntimeStatistics(
                publicKey: try PublicKey(base64Encoded: SampleKeys.firstPeerPublicKeyText),
                receivedByteCount: 10,
                transmittedByteCount: 20,
                latestHandshake: Date(timeIntervalSince1970: 1_793_268_000)
            )
        ])
        environment.engine.network.state.update { snapshot in snapshot.statistics = statistics }

        let statisticsResponse = await handler.handle(.runtimeStatistics)
        let healthResponse = await handler.handle(.healthCheck)

        #expect(statisticsResponse == .runtimeStatistics(statistics: statistics))
        #expect(healthResponse == .health(isTunnelRunning: true))
    }

    @Test
    func reportsThatTheTunnelIsNotRunningBeforeTheStart() async throws {
        let handler = TransparentProxyMessageHandler(session: TransparentProxyTestEnvironment().session)
        let policy = RoutingPolicy(mode: try TransparentProxyTestEnvironment.selectedBrowser())

        let policyResponse = await handler.handle(.applyRoutingPolicy(policy: policy))
        let statisticsResponse = await handler.handle(.runtimeStatistics)
        let healthResponse = await handler.handle(.healthCheck)

        #expect(policyResponse == .failure(reason: .tunnelNotRunning))
        #expect(statisticsResponse == .failure(reason: .tunnelNotRunning))
        #expect(healthResponse == .health(isTunnelRunning: false))
    }

    private static func startedEnvironment() async throws -> TransparentProxyTestEnvironment {
        let environment = TransparentProxyTestEnvironment()
        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )
        return environment
    }
}
