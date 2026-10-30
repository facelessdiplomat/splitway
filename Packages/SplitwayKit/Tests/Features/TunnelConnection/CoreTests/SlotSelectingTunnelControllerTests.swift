import AppRouting
import Foundation
import Testing
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary

@Suite
struct SlotSelectingTunnelControllerTests {
    private let office: Tunnel
    private let browsing: Tunnel
    private let packetTunnel = FakeSystemTunnelController()
    private let transparentProxy = FakeSystemTunnelController()

    init() throws {
        office = try ConnectionTestTunnels.named("Office")
        browsing = try ConnectionTestTunnels.named("Browsing")
            .routed(by: RoutingPolicy(mode: .selectedApplications(ApplicationSelection([]))))
    }

    @Test
    func installsATunnelOfAllTrafficIntoThePacketTunnelSlot() async throws {
        try await controller().install(office)

        #expect(await packetTunnel.operations == [.install(office.id)])
        #expect(await transparentProxy.operations.isEmpty)
    }

    @Test
    func installsATunnelOfSelectedApplicationsIntoTheProxySlot() async throws {
        try await controller().install(browsing)

        #expect(await transparentProxy.operations == [.install(browsing.id)])
        #expect(await packetTunnel.operations.isEmpty)
    }

    @Test
    func startsTheSlotOfTheInstalledTunnel() async throws {
        let controller = controller()

        try await controller.install(browsing)
        try await controller.start()

        #expect(await transparentProxy.operations == [.install(browsing.id), .start])
        #expect(await packetTunnel.operations.isEmpty)
    }

    @Test
    func stopsTheActiveSlotOfAnotherModeBeforeInstalling() async throws {
        let packetTunnel = FakeSystemTunnelController(installed: office.id, status: .connected(since: .distantPast))
        let controller = SlotSelectingTunnelController(packetTunnel: packetTunnel, transparentProxy: transparentProxy)

        try await controller.install(browsing)

        #expect(await packetTunnel.operations == [.stop])
        #expect(await transparentProxy.operations == [.install(browsing.id)])
    }

    @Test
    func stoppingStopsBothSlots() async {
        await controller().stop()

        #expect(await packetTunnel.operations == [.stop])
        #expect(await transparentProxy.operations == [.stop])
    }

    @Test
    func reportsTheTunnelAndStatusOfTheActiveSlot() async {
        let transparentProxy = FakeSystemTunnelController(
            installed: browsing.id,
            status: .connected(since: .distantPast)
        )
        let controller = SlotSelectingTunnelController(packetTunnel: packetTunnel, transparentProxy: transparentProxy)

        #expect(await controller.installedTunnel() == browsing.id)
        #expect(await controller.currentStatus() == .connected(since: .distantPast))
    }

    @Test
    func reportsTheSlotOfTheLastInstalledTunnel() async throws {
        let packetTunnel = FakeSystemTunnelController(installed: office.id)
        let transparentProxy = FakeSystemTunnelController(disconnectFailure: .endpointUnresolvable)
        let controller = SlotSelectingTunnelController(packetTunnel: packetTunnel, transparentProxy: transparentProxy)

        try await controller.install(browsing)

        #expect(await controller.installedTunnel() == browsing.id)
        #expect(await controller.lastDisconnectFailure() == .endpointUnresolvable)
    }

    @Test
    func forwardsStatusUpdatesOfTheSelectedSlot() async throws {
        let controller = controller()
        var updates = controller.statusUpdates().makeAsyncIterator()

        try await controller.install(browsing)
        transparentProxy.emit(.connecting, .connected(since: .distantPast))

        #expect(await updates.next() == .connecting)
        #expect(await updates.next() == .connected(since: .distantPast))
    }

    @Test
    func followsAnotherSlotOnlyWhenItBecomesActive() async throws {
        let controller = controller()
        var updates = controller.statusUpdates().makeAsyncIterator()

        try await controller.install(browsing)
        packetTunnel.emit(.disconnected, .connecting)

        #expect(await updates.next() == .connecting)
        #expect(await controller.installedTunnel() == nil)
    }

    @Test
    func activatingATunnelOfAnotherModeMovesTheConnectionToItsSlot() async throws {
        let packetTunnel = FakeSystemTunnelController(installed: office.id, status: .connected(since: .distantPast))
        let controller = SlotSelectingTunnelController(packetTunnel: packetTunnel, transparentProxy: transparentProxy)

        try await ConnectionCoordinator(controller: controller).activate(browsing)

        #expect(await packetTunnel.operations == [.stop])
        #expect(await transparentProxy.operations == [.stop, .install(browsing.id), .start])
    }

    private func controller() -> SlotSelectingTunnelController {
        SlotSelectingTunnelController(packetTunnel: packetTunnel, transparentProxy: transparentProxy)
    }
}
