import AppRouting
import MenuBar
import MenuBarPresentation
import Testing
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary

@MainActor
@Suite
struct MenuBarModelTests {
    @Test
    func listsTheTunnelsAndMarksTheActiveOne() async throws {
        let environment = MenuBarTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        try await environment.storeTunnel(named: "Home")
        await environment.tunnels.load()

        environment.connect(office)

        #expect(environment.model.items.map(\.name) == ["Office", "Home"])
        #expect(environment.model.items.map(\.isActive) == [true, false])
        #expect(environment.model.icon == .connected)
        #expect(environment.model.activeTunnel?.name == "Office")
    }

    @Test
    func showsTheRoutingModeOfTheActiveTunnel() async throws {
        let environment = MenuBarTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        await environment.tunnels.load()

        environment.connect(office)

        #expect(environment.model.activeTunnel?.routingMode == .allTraffic)
    }

    @Test
    func hasNoActiveTunnelWhileEverythingIsDisconnected() async throws {
        let environment = MenuBarTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        await environment.tunnels.load()

        environment.tunnels.apply(SlotState(tunnelID: office.id, connection: .disconnected))

        #expect(environment.model.activeTunnel == nil)
        #expect(environment.model.icon == .disconnected)
    }

    @Test
    func headlinesTheActiveOrFailedTunnel() async throws {
        let environment = MenuBarTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        try await environment.storeTunnel(named: "Home")
        await environment.tunnels.load()

        environment.tunnels.apply(SlotState(tunnelID: office.id, connection: .failed(.permissionDenied)))

        #expect(environment.model.headlineTunnel?.name == "Office")
        #expect(environment.model.activeTunnel == nil)
        #expect(environment.model.icon == .failed)
    }

    @Test
    func connectsTheSelectedTunnel() async throws {
        let environment = MenuBarTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        await environment.tunnels.load()
        environment.tunnels.apply(SlotState(tunnelID: office.id, connection: .disconnected))

        await environment.model.select(try environment.item(named: "Office"))

        #expect(await environment.controller.operations == [.install(office.id), .start])
    }

    @Test
    func disconnectsTheActiveTunnelWhenItIsSelected() async throws {
        let controller = FakeSystemTunnelController(status: .connected(since: MenuBarTestEnvironment.connectedSince))
        let environment = MenuBarTestEnvironment(controller: controller)
        let office = try await environment.storeTunnel(named: "Office")
        await environment.tunnels.load()
        environment.connect(office)

        await environment.model.select(try environment.item(named: "Office"))

        #expect(await environment.controller.operations == [.stop])
    }

    @Test
    func stopsTheCurrentTunnelWhenAnotherIsSelected() async throws {
        let environment = MenuBarTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        let home = try await environment.storeTunnel(named: "Home")
        await environment.tunnels.load()
        environment.tunnels.apply(SlotState(tunnelID: office.id, connection: .disconnected))
        await environment.model.select(try environment.item(named: "Office"))
        environment.tunnels.apply(SlotState(tunnelID: office.id, connection: .connecting))

        await environment.model.select(try environment.item(named: "Home"))

        #expect(
            await environment.controller.operations == [.install(office.id), .start, .stop, .install(home.id), .start]
        )
    }

    @Test
    func opensTheMainWindowToExplainTheFirstSystemPrompt() async throws {
        let environment = MenuBarTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        await environment.tunnels.load()

        await environment.model.select(try environment.item(named: "Office"))

        #expect(environment.tunnels.tunnelAwaitingSystemPrompt == office.id)
        #expect(environment.model.isMainWindowRequested)
        #expect(await environment.controller.operations.isEmpty)
    }

    @Test
    func activatesTheApplicationForTheMainWindow() {
        let environment = MenuBarTestEnvironment()

        environment.model.requestMainWindow()

        #expect(environment.model.isMainWindowRequested)
        #expect(environment.lifecycle.activationCount == 1)
        environment.model.mainWindowShown()
        #expect(!environment.model.isMainWindowRequested)
    }

    @Test
    func hasNoTunnelsWhenTheLibraryIsEmpty() async {
        let environment = MenuBarTestEnvironment()

        await environment.tunnels.load()

        #expect(environment.model.hasNoTunnels)
        #expect(environment.model.items.isEmpty)
    }

    @Test
    func quitsRightAwayWithoutAnActiveTunnel() async throws {
        let environment = MenuBarTestEnvironment(quitAnswer: .stay)
        try await environment.storeTunnel(named: "Office")
        await environment.tunnels.load()

        await environment.model.quit()

        #expect(environment.lifecycle.isTerminated)
        #expect(environment.confirmation.askedTunnelNames.isEmpty)
    }

    @Test
    func disconnectsTheActiveTunnelBeforeQuittingWhenAsked() async throws {
        let controller = FakeSystemTunnelController(status: .connected(since: MenuBarTestEnvironment.connectedSince))
        let environment = MenuBarTestEnvironment(controller: controller, quitAnswer: .disconnectAndQuit)
        let office = try await environment.storeTunnel(named: "Office")
        await environment.tunnels.load()
        environment.connect(office)

        await environment.model.quit()

        #expect(environment.confirmation.askedTunnelNames == ["Office"])
        #expect(await environment.controller.operations == [.stop])
        #expect(environment.lifecycle.isTerminated)
    }

    @Test
    func keepsTheTunnelWhenQuittingWithoutDisconnecting() async throws {
        let environment = MenuBarTestEnvironment(quitAnswer: .quitKeepingConnection)
        let office = try await environment.storeTunnel(named: "Office")
        await environment.tunnels.load()
        environment.connect(office)

        await environment.model.quit()

        #expect(await environment.controller.operations.isEmpty)
        #expect(environment.lifecycle.isTerminated)
    }

    @Test
    func staysWhenQuittingIsCancelled() async throws {
        let environment = MenuBarTestEnvironment(quitAnswer: .stay)
        let office = try await environment.storeTunnel(named: "Office")
        await environment.tunnels.load()
        environment.connect(office)

        await environment.model.quit()

        #expect(await environment.controller.operations.isEmpty)
        #expect(!environment.lifecycle.isTerminated)
    }
}
