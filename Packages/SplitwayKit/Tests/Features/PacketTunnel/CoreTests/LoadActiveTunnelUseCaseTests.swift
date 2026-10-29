import AppRouting
import PacketTunnel
import ProviderMessaging
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelLibrary
import TunnelLibraryTestSupport

@Suite
struct LoadActiveTunnelUseCaseTests {
    private let tunnelID = TunnelIdentifier()

    @Test
    func loadsTheConfigurationOfTheTunnelInTheSlot() async throws {
        let secrets = InMemoryTunnelSecretStore(texts: [tunnelID: WgQuickFixtures.minimal])
        let slot = try Self.providerConfiguration(
            for: tunnelID, routingPolicy: RoutingPolicy(mode: .allTraffic, whenTunnelUnavailable: .bypass))

        let activeTunnel = try await LoadActiveTunnelUseCase(secrets: secrets).execute(providerConfiguration: slot)

        #expect(activeTunnel.id == tunnelID)
        #expect(
            activeTunnel.configuration
                == (try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)))
        #expect(activeTunnel.routingPolicy.whenTunnelUnavailable == .bypass)
    }

    @Test
    func reportsASlotWithoutATunnel() async {
        let useCase = LoadActiveTunnelUseCase(secrets: InMemoryTunnelSecretStore())

        await #expect(throws: PacketTunnelError.configurationUnavailable) {
            try await useCase.execute(providerConfiguration: nil)
        }
    }

    @Test
    func reportsATunnelWhoseSecretIsMissing() async throws {
        let useCase = LoadActiveTunnelUseCase(secrets: InMemoryTunnelSecretStore())
        let slot = try Self.providerConfiguration(for: tunnelID, routingPolicy: .default)

        await #expect(throws: PacketTunnelError.configurationUnavailable) {
            try await useCase.execute(providerConfiguration: slot)
        }
    }

    @Test
    func reportsAStoredConfigurationThatNoLongerParses() async throws {
        let useCase = LoadActiveTunnelUseCase(secrets: InMemoryTunnelSecretStore(texts: [tunnelID: "[Peer]\n"]))
        let slot = try Self.providerConfiguration(for: tunnelID, routingPolicy: .default)

        await #expect(throws: PacketTunnelError.configurationUnavailable) {
            try await useCase.execute(providerConfiguration: slot)
        }
    }

    private static func providerConfiguration(
        for tunnelID: TunnelIdentifier,
        routingPolicy: RoutingPolicy
    ) throws -> [String: Any] {
        try TunnelProviderConfigurationCodec.dictionary(
            for: TunnelProviderConfiguration(tunnelID: tunnelID, routingPolicy: routingPolicy)
        )
    }
}
