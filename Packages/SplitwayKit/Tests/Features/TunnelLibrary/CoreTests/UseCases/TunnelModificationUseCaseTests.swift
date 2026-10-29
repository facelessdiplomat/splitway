import AppRouting
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelLibrary

@Suite
struct TunnelModificationUseCaseTests {
    @Test
    func updatesTheConfigurationAndRoutingPolicy() async throws {
        let environment = LibraryTestEnvironment()
        let tunnel = try await environment.storedTunnel(named: "Office")
        let newConfiguration = try environment.configuration(of: WgQuickFixtures.full)
        let newPolicy = RoutingPolicy(mode: .allTraffic, whenTunnelUnavailable: .bypass)

        let updated = try await environment.updateTunnel.execute(
            id: tunnel.id,
            configuration: newConfiguration,
            routingPolicy: newPolicy
        )

        #expect(updated.configuration == newConfiguration)
        #expect(try await environment.loadTunnels.execute().tunnels == [updated])
    }

    @Test
    func restoresThePreviousConfigurationWhenTheRecordCannotBeSaved() async throws {
        let environment = LibraryTestEnvironment()
        let tunnel = try await environment.storedTunnel(named: "Office")
        let originalText = await environment.secrets.texts[tunnel.id]
        await environment.records.failSaves(afterSuccessfulSaves: 0)

        await #expect(throws: TunnelLibraryError.storage(.unavailable)) {
            try await environment.updateTunnel.execute(
                id: tunnel.id,
                configuration: environment.configuration(of: WgQuickFixtures.full),
                routingPolicy: .default
            )
        }
        #expect(await environment.secrets.texts[tunnel.id] == originalText)
    }

    @Test
    func reportsUnknownTunnels() async throws {
        let environment = LibraryTestEnvironment()
        let unknown = TunnelIdentifier()

        await #expect(throws: TunnelLibraryError.tunnelNotFound(unknown)) {
            try await environment.renameTunnel.execute(id: unknown, to: TunnelName("Anything"))
        }
    }

    @Test
    func renamesToAUniqueNameButKeepsItsOwnName() async throws {
        let environment = LibraryTestEnvironment()
        let office = try await environment.storedTunnel(named: "Office")
        try await environment.storedTunnel(named: "Home")

        let conflicting = try await environment.renameTunnel.execute(id: office.id, to: TunnelName("Home"))
        let unchanged = try await environment.renameTunnel.execute(id: office.id, to: TunnelName("Home 2"))

        #expect(conflicting.description == "Home 2")
        #expect(unchanged.description == "Home 2")
    }

    @Test
    func duplicatesWithANewIdentityAndAUniqueName() async throws {
        let environment = LibraryTestEnvironment()
        let office = try await environment.storedTunnel(named: "Office")

        let copy = try await environment.duplicateTunnel.execute(id: office.id)

        #expect(copy.id != office.id)
        #expect(copy.name.description == "Office 2")
        #expect(copy.configuration == office.configuration)
        #expect(copy.routingPolicy == office.routingPolicy)
    }

    @Test
    func reordersTunnelsAndRejectsOrdersThatDoNotMatch() async throws {
        let environment = LibraryTestEnvironment()
        let first = try await environment.storedTunnel(named: "First")
        let second = try await environment.storedTunnel(named: "Second")

        try await environment.reorderTunnels.execute(order: [second.id, first.id])

        #expect(await environment.records.records.map(\.id) == [second.id, first.id])
        await #expect(throws: TunnelLibraryError.orderDoesNotMatchTunnels) {
            try await environment.reorderTunnels.execute(order: [first.id])
        }
    }
}
