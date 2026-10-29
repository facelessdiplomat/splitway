import Testing
import TunnelConnection
import TunnelLibrary

@Suite
struct ConnectionCoordinatorTests {
    private let office: Tunnel
    private let prague: Tunnel

    init() throws {
        office = try ConnectionTestTunnels.named("Office")
        prague = try ConnectionTestTunnels.named("Prague")
    }

    @Test
    func installsAndStartsATunnelInAnIdleSlot() async throws {
        let controller = FakeSystemTunnelController()

        try await ConnectionCoordinator(controller: controller).activate(office)

        #expect(await controller.operations == [.install(office.id), .start])
    }

    @Test
    func stopsAnotherActiveTunnelBeforeActivating() async throws {
        let controller = FakeSystemTunnelController(installed: prague.id, status: .connected(since: .distantPast))

        try await ConnectionCoordinator(controller: controller).activate(office)

        #expect(await controller.operations == [.stop, .install(office.id), .start])
    }

    @Test
    func ignoresARepeatedActivationWhileConnecting() async throws {
        let controller = FakeSystemTunnelController(installed: office.id, status: .connecting)

        try await ConnectionCoordinator(controller: controller).activate(office)

        #expect(await controller.operations.isEmpty)
    }

    @Test
    func reinstallsTheSameTunnelWhenItIsNotRunning() async throws {
        let controller = FakeSystemTunnelController(installed: office.id, status: .disconnected)

        try await ConnectionCoordinator(controller: controller).activate(office)

        #expect(await controller.operations == [.install(office.id), .start])
    }

    @Test
    func reportsAFailureToSaveTheSystemSlotWithoutStarting() async {
        let controller = FakeSystemTunnelController(installFailure: .permissionDenied)
        let coordinator = ConnectionCoordinator(controller: controller)
        let office = office

        await #expect(throws: ConnectionFailure.permissionDenied) {
            try await coordinator.activate(office)
        }
        #expect(await controller.operations == [.install(office.id)])
    }

    @Test
    func stopsTheRunningTunnelOnDeactivation() async {
        let controller = FakeSystemTunnelController(installed: office.id, status: .connected(since: .distantPast))

        await ConnectionCoordinator(controller: controller).deactivate()

        #expect(await controller.operations == [.stop])
    }

    @MainActor
    @Test
    func theLastUserActionWinsOverEarlierOnes() async throws {
        let controller = FakeSystemTunnelController()
        await controller.holdNextInstall()
        let coordinator = ConnectionCoordinator(controller: controller)
        let office = office
        let prague = prague

        let firstActivation = Task { try? await coordinator.activate(office) }
        await controller.waitUntilInstallIsHeld()
        let secondActivation = Task { try? await coordinator.activate(prague) }
        let deactivation = Task { await coordinator.deactivate() }
        await controller.releaseHeldInstall()
        await firstActivation.value
        await secondActivation.value
        await deactivation.value

        #expect(await controller.operations == [.install(office.id), .stop])
    }

    @MainActor
    @Test
    func aLaterActivationReplacesAnEarlierOneInFlight() async throws {
        let controller = FakeSystemTunnelController()
        await controller.holdNextInstall()
        let coordinator = ConnectionCoordinator(controller: controller)
        let office = office
        let prague = prague

        let firstActivation = Task { try? await coordinator.activate(office) }
        await controller.waitUntilInstallIsHeld()
        let secondActivation = Task { try? await coordinator.activate(prague) }
        await controller.releaseHeldInstall()
        await firstActivation.value
        await secondActivation.value

        #expect(await controller.operations == [.install(office.id), .install(prague.id), .start])
    }
}
