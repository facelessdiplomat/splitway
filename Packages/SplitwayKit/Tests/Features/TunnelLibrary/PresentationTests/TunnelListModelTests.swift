import Foundation
import Testing
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary
import TunnelLibraryPresentation

@MainActor
@Suite
struct TunnelListModelTests {
    private static let connectedMoment = Date(timeIntervalSince1970: 1_793_268_900)

    @Test
    func showsEveryTunnelWithTheStateOfTheSlot() async throws {
        let environment = TunnelListTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        try await environment.storeTunnel(named: "Prague")
        await environment.model.load()

        environment.model.apply(SlotState(tunnelID: office.id, connection: .connected(since: Self.connectedMoment)))

        #expect(environment.model.rows.map(\.name) == ["Office", "Prague"])
        #expect(environment.model.rows.map(\.status) == [.connected(since: Self.connectedMoment), .disconnected])
        #expect(environment.model.rows.map(\.isConnectionActive) == [true, false])
        #expect(environment.model.rows.map(\.routingMode) == [.allTraffic, .allTraffic])
    }

    @Test
    func listsTunnelsWhoseConfigurationIsUnreadable() async throws {
        let environment = TunnelListTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        try await environment.secrets.deleteConfigurationText(for: office.id)

        await environment.model.load()

        #expect(environment.model.rows.map(\.status) == [.unavailable])
        #expect(environment.model.rows.first?.canToggleConnection == false)
        #expect(environment.model.rows.first?.canDuplicate == false)
        #expect(environment.model.rows.first?.canExport == false)
    }

    @Test
    func keepsAnUnreadableTunnelInItsStoredPlace() async throws {
        let environment = TunnelListTestEnvironment()
        try await environment.storeTunnel(named: "Office")
        let broken = try await environment.storeTunnel(named: "Broken")
        try await environment.storeTunnel(named: "Prague")
        try await environment.secrets.deleteConfigurationText(for: broken.id)

        await environment.model.load()

        #expect(environment.model.rows.map(\.name) == ["Office", "Broken", "Prague"])
    }

    @Test
    func showsTheEmptyStateOnlyAfterLoading() async {
        let environment = TunnelListTestEnvironment()
        #expect(!environment.model.isEmpty)

        await environment.model.load()

        #expect(environment.model.isEmpty)
    }

    @Test
    func asksBeforeDeletingAndWarnsWhenTheTunnelIsConnected() async throws {
        let environment = TunnelListTestEnvironment()
        let stored = try await environment.storeTunnel(named: "Office")
        await environment.model.load()
        environment.model.apply(SlotState(tunnelID: stored.id, connection: .connected(since: Self.connectedMoment)))
        let row = try #require(environment.model.rows.first)

        environment.model.requestDeletion(of: row)

        #expect(
            environment.model.pendingDeletion
                == TunnelDeletionRequest(tunnelID: stored.id, tunnelName: "Office", disconnectsTunnel: true)
        )
        #expect(try await environment.records.loadRecords().count == 1)
    }

    @Test
    func asksAboutDeletionOnlyNextToTheRequestedTunnel() async throws {
        let environment = TunnelListTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        let prague = try await environment.storeTunnel(named: "Prague")
        await environment.model.load()

        environment.model.requestDeletion(of: try #require(environment.model.row(withID: prague.id)))

        #expect(environment.model.deletionRequest(for: office.id) == nil)
        #expect(environment.model.deletionRequest(for: prague.id)?.tunnelName == "Prague")
    }

    @Test
    func deletesOnlyAfterConfirmation() async throws {
        let environment = TunnelListTestEnvironment()
        try await environment.storeTunnel(named: "Office")
        await environment.model.load()
        environment.model.requestDeletion(of: try #require(environment.model.rows.first))

        await environment.model.confirmDeletion(of: try #require(environment.model.pendingDeletion))

        #expect(environment.model.pendingDeletion == nil)
        #expect(environment.model.rows.isEmpty)
    }

    @Test
    func keepsTheTunnelWhenDeletionIsCancelled() async throws {
        let environment = TunnelListTestEnvironment()
        try await environment.storeTunnel(named: "Office")
        await environment.model.load()
        environment.model.requestDeletion(of: try #require(environment.model.rows.first))

        environment.model.cancelDeletion()

        #expect(environment.model.pendingDeletion == nil)
        #expect(environment.model.rows.map(\.name) == ["Office"])
    }

    @Test
    func savesTheNewOrderThroughTheLibrary() async throws {
        let environment = TunnelListTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        let prague = try await environment.storeTunnel(named: "Prague")
        await environment.model.load()

        await environment.model.move(fromOffsets: IndexSet(integer: 1), toOffset: 0)

        #expect(environment.model.rows.map(\.name) == ["Prague", "Office"])
        #expect(try await environment.records.loadRecords().map(\.id) == [prague.id, office.id])
    }

    @Test
    func duplicatesATunnelUnderAFreeName() async throws {
        let environment = TunnelListTestEnvironment()
        try await environment.storeTunnel(named: "Office")
        await environment.model.load()

        await environment.model.duplicate(try #require(environment.model.rows.first))

        #expect(environment.model.rows.map(\.name) == ["Office", "Office 2"])
    }

    @Test
    func findsTheRowOfTheSelectedTunnel() async throws {
        let environment = TunnelListTestEnvironment()
        try await environment.storeTunnel(named: "Office")
        let prague = try await environment.storeTunnel(named: "Prague")
        await environment.model.load()

        let row = environment.model.row(withID: prague.id)

        #expect(row?.name == "Prague")
        #expect(environment.model.row(withID: TunnelIdentifier()) == nil)
    }

    @Test
    func providesTheConfigurationOnlyOfAReadableTunnel() async throws {
        let environment = TunnelListTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        let broken = try await environment.storeTunnel(named: "Broken")
        try await environment.secrets.deleteConfigurationText(for: broken.id)
        await environment.model.load()

        #expect(environment.model.tunnel(withID: office.id) == office)
        #expect(environment.model.tunnel(withID: broken.id) == nil)
    }
}
