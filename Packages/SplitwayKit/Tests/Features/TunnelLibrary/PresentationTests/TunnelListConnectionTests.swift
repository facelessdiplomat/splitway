import Foundation
import Testing
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary
import TunnelLibraryPresentation

@MainActor
@Suite
struct TunnelListConnectionTests {
    @Test
    func connectsAnInactiveTunnelAndDisconnectsAnActiveOne() async throws {
        let environment = TunnelListTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        await environment.model.load()
        environment.model.apply(SlotState(tunnelID: office.id, connection: .disconnected))

        await environment.model.toggleConnection(of: try #require(environment.model.rows.first))
        environment.model.apply(SlotState(tunnelID: office.id, connection: .connecting))
        await environment.model.toggleConnection(of: try #require(environment.model.rows.first))

        #expect(await environment.controller.operations == [.install(office.id), .start, .stop])
    }

    @Test
    func reportsAFailedConnectionAttempt() async throws {
        let controller = FakeSystemTunnelController(installFailure: .permissionDenied)
        let environment = TunnelListTestEnvironment(controller: controller)
        let office = try await environment.storeTunnel(named: "Office")
        await environment.model.load()
        environment.model.apply(SlotState(tunnelID: office.id, connection: .disconnected))

        await environment.model.toggleConnection(of: try #require(environment.model.rows.first))

        #expect(environment.model.alert == .connection(.permissionDenied, tunnel: office.id))
        #expect(environment.model.rows.first?.status == .disconnected)
        environment.model.dismissAlert()
        #expect(environment.model.alert == nil)
    }

    @Test
    func explainsTheSystemPromptBeforeTheFirstConnection() async throws {
        let environment = TunnelListTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        await environment.model.load()

        await environment.model.toggleConnection(of: try #require(environment.model.rows.first))

        #expect(environment.model.tunnelAwaitingSystemPrompt == office.id)
        #expect(await environment.controller.operations.isEmpty)
        await environment.model.continueToSystemPrompt()
        #expect(environment.model.tunnelAwaitingSystemPrompt == nil)
        #expect(await environment.controller.operations == [.install(office.id), .start])
    }

    @Test
    func connectsNothingWhenTheExplanationIsDismissed() async throws {
        let environment = TunnelListTestEnvironment()
        try await environment.storeTunnel(named: "Office")
        await environment.model.load()
        await environment.model.toggleConnection(of: try #require(environment.model.rows.first))

        environment.model.dismissSystemPromptExplanation()

        #expect(environment.model.tunnelAwaitingSystemPrompt == nil)
        #expect(await environment.controller.operations.isEmpty)
    }

    @Test
    func showsConnectingAsSoonAsTheToggleIsTapped() async throws {
        let environment = TunnelListTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        await environment.model.load()
        environment.model.apply(SlotState(tunnelID: office.id, connection: .disconnected))
        await environment.controller.holdNextInstall()
        let row = try #require(environment.model.rows.first)

        let connecting = Task { await environment.model.toggleConnection(of: row) }
        await environment.controller.waitUntilInstallIsHeld()

        #expect(environment.model.rows.first?.status == .connecting)
        await environment.controller.releaseHeldInstall()
        await connecting.value
    }

    @Test
    func disconnectsWhenTappedAgainWhileConnecting() async throws {
        let environment = TunnelListTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        await environment.model.load()
        environment.model.apply(SlotState(tunnelID: office.id, connection: .disconnected))
        await environment.controller.holdNextInstall()
        let connecting = Task {
            await environment.model.toggleConnection(of: try #require(environment.model.rows.first))
        }
        await environment.controller.waitUntilInstallIsHeld()

        let disconnecting = Task {
            await environment.model.toggleConnection(of: try #require(environment.model.rows.first))
        }
        await Task.yield()
        await environment.controller.releaseHeldInstall()
        _ = await connecting.result
        _ = await disconnecting.result

        #expect(await environment.controller.operations == [.install(office.id), .stop])
        #expect(environment.model.rows.first?.status == .disconnected)
    }
}
