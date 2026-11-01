import AppRouting
import PacketTunnel
import ProviderMessaging
import ServiceCatalog
import ServiceCatalogTestSupport
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
    func appliesNewNetworkSettingsWhenTheSelectedServicesBringNewDomains() async throws {
        let telegram = try Self.service("telegram", "telegram.org")
        let youtube = try Self.service("youtube", "youtube.com")
        let environment = try SessionTestEnvironment(services: [telegram, youtube])
        try await environment.start(routedBy: SessionTestEnvironment.policy(selecting: [telegram]))
        let settings = RecordingNetworkSettings()

        let response = await Self.handler(of: environment, settings: settings)
            .handle(.applyRoutingPolicy(policy: SessionTestEnvironment.policy(selecting: [telegram, youtube])))

        #expect(response == .routingPolicyApplied)
        #expect(
            settings.appliedPlans.map(\.dns?.scope)
                == [.matchingDomains([try DomainName("telegram.org"), try DomainName("youtube.com")])]
        )
        #expect(environment.device.receivedTranslations.count == 2)
    }

    @Test
    func keepsTheNetworkSettingsWhenANewSelectionLeavesRoutesAndDomainsAlone() async throws {
        let telegram = try Self.service("telegram", "telegram.org")
        let telegramWeb = try Self.service("telegram-web", "web.telegram.org")
        let environment = try SessionTestEnvironment(services: [telegram, telegramWeb])
        try await environment.start(routedBy: SessionTestEnvironment.policy(selecting: [telegram]))
        let settings = RecordingNetworkSettings()

        let response = await Self.handler(of: environment, settings: settings)
            .handle(.applyRoutingPolicy(policy: SessionTestEnvironment.policy(selecting: [telegram, telegramWeb])))

        #expect(response == .routingPolicyApplied)
        #expect(settings.appliedPlans.isEmpty)
    }

    @Test
    func asksForARestartWhenTheRoutingModeChanges() async throws {
        let telegram = try Self.service("telegram", "telegram.org")
        let environment = try SessionTestEnvironment(services: [telegram])
        try await environment.start()
        let settings = RecordingNetworkSettings()

        let response = await Self.handler(of: environment, settings: settings)
            .handle(.applyRoutingPolicy(policy: SessionTestEnvironment.policy(selecting: [telegram])))

        #expect(response == .failure(reason: .routingPolicyRejected))
        #expect(settings.appliedPlans.isEmpty)
        #expect(environment.device.receivedTranslations.isEmpty)
    }

    @Test
    func explainsThatAStoppedTunnelCannotChangeItsRouting() async throws {
        let environment = try SessionTestEnvironment()

        let response = await Self.handler(of: environment).handle(.applyRoutingPolicy(policy: .default))

        #expect(response == .failure(reason: .tunnelNotRunning))
    }

    @Test
    func keepsTheCurrentRoutingWhenTheSystemRefusesTheNewSettings() async throws {
        let telegram = try Self.service("telegram", "telegram.org")
        let youtube = try Self.service("youtube", "youtube.com")
        let environment = try SessionTestEnvironment(services: [telegram, youtube])
        try await environment.start(routedBy: SessionTestEnvironment.policy(selecting: [telegram]))
        let both = SessionTestEnvironment.policy(selecting: [telegram, youtube])
        let refusing = RecordingNetworkSettings(failure: .networkSettingsRejected)
        let settings = RecordingNetworkSettings()

        let refused = await Self.handler(of: environment, settings: refusing).handle(.applyRoutingPolicy(policy: both))
        let retried = await Self.handler(of: environment, settings: settings).handle(.applyRoutingPolicy(policy: both))

        #expect(refused == .failure(reason: .routingPolicyRejected))
        #expect(retried == .routingPolicyApplied)
        #expect(settings.appliedPlans.count == 1)
    }

    private static func handler(
        of environment: SessionTestEnvironment,
        settings: RecordingNetworkSettings = RecordingNetworkSettings()
    ) -> PacketTunnelMessageHandler {
        PacketTunnelMessageHandler(session: environment.session, networkSettings: settings)
    }

    private static func service(_ id: String, _ domain: String) throws -> ServiceProfile {
        try ServiceCatalogFixtures.profile(id: id, name: id, domains: [domain])
    }
}
