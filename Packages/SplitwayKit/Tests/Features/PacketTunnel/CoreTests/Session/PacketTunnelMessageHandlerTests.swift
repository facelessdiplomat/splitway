import AppRouting
import PacketTunnel
import ProviderMessaging
import SharedKernel
import Testing
import TunnelEngine

@Suite
struct PacketTunnelMessageHandlerTests {
    @Test
    func reportsTheStatisticsOfTheRunningTunnel() async throws {
        let environment = try SessionTestEnvironment()
        try await environment.start()

        let response = await Self.handler(of: environment).handle(.runtimeStatistics)

        #expect(response == .runtimeStatistics(statistics: RuntimeStatistics(peers: [])))
    }

    @Test
    func explainsThatAStoppedTunnelHasNoStatistics() async throws {
        let environment = try SessionTestEnvironment()

        let response = await Self.handler(of: environment).handle(.runtimeStatistics)

        #expect(response == .failure(reason: .tunnelNotRunning))
    }

    @Test
    func reportsTheHealthOfTheTunnel() async throws {
        let environment = try SessionTestEnvironment()
        let handler = Self.handler(of: environment)
        #expect(await handler.handle(.healthCheck) == .health(isTunnelRunning: false))

        try await environment.start()

        #expect(await handler.handle(.healthCheck) == .health(isTunnelRunning: true))
    }

    @Test
    func keepsTheSettingsOfAFullTunnelWhosePolicyStaysTheSame() async throws {
        let environment = try SessionTestEnvironment()
        try await environment.start()
        let settings = RecordingNetworkSettings()

        let response = await Self.handler(of: environment, settings: settings)
            .handle(.applyRoutingPolicy(policy: .default))

        #expect(response == .routingPolicyApplied)
        #expect(settings.appliedPlans.isEmpty)
    }

    @Test
    func asksForARestartWhenTheRoutingModeChanges() async throws {
        let environment = try SessionTestEnvironment()
        try await environment.start()
        let settings = RecordingNetworkSettings()
        let applications = RoutingPolicy(mode: .selectedApplications(ApplicationSelection([])))

        let response = await Self.handler(of: environment, settings: settings)
            .handle(.applyRoutingPolicy(policy: applications))

        #expect(response == .failure(reason: .routingPolicyRejected))
        #expect(settings.appliedPlans.isEmpty)
    }

    @Test
    func explainsThatAStoppedTunnelCannotChangeItsRouting() async throws {
        let environment = try SessionTestEnvironment()

        let response = await Self.handler(of: environment).handle(.applyRoutingPolicy(policy: .default))

        #expect(response == .failure(reason: .tunnelNotRunning))
    }

    private static func handler(
        of environment: SessionTestEnvironment,
        settings: RecordingNetworkSettings = RecordingNetworkSettings()
    ) -> PacketTunnelMessageHandler {
        PacketTunnelMessageHandler(session: environment.session, networkSettings: settings)
    }

}
