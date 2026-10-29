import AppRouting
import PacketTunnel
import ProviderMessaging
import Testing
import TunnelEngine

@Suite
struct PacketTunnelMessageHandlerTests {
    @Test
    func reportsTheStatisticsOfTheRunningTunnel() async throws {
        let environment = try SessionTestEnvironment()
        try await environment.start()

        let response = await PacketTunnelMessageHandler(session: environment.session).handle(.runtimeStatistics)

        #expect(response == .runtimeStatistics(statistics: RuntimeStatistics(peers: [])))
    }

    @Test
    func explainsThatAStoppedTunnelHasNoStatistics() async throws {
        let environment = try SessionTestEnvironment()

        let response = await PacketTunnelMessageHandler(session: environment.session).handle(.runtimeStatistics)

        #expect(response == .failure(reason: .tunnelNotRunning))
    }

    @Test
    func reportsTheHealthOfTheTunnel() async throws {
        let environment = try SessionTestEnvironment()
        let handler = PacketTunnelMessageHandler(session: environment.session)
        #expect(await handler.handle(.healthCheck) == .health(isTunnelRunning: false))

        try await environment.start()

        #expect(await handler.handle(.healthCheck) == .health(isTunnelRunning: true))
    }

    @Test
    func acceptsOnlyTheRoutingPolicyAFullTunnelServes() async throws {
        let environment = try SessionTestEnvironment()
        let handler = PacketTunnelMessageHandler(session: environment.session)
        let services = RoutingPolicy(mode: .selectedServices(ServiceSelection([try ServiceIdentifier("telegram")])))

        #expect(await handler.handle(.applyRoutingPolicy(policy: .default)) == .routingPolicyApplied)
        #expect(await handler.handle(.applyRoutingPolicy(policy: services)) == .failure(reason: .routingPolicyRejected))
    }
}
