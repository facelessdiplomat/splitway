import AppRouting
import ProviderMessaging
import Testing
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary

@Suite
struct SlotSelectingMessengerTests {
    private let packetTunnelMessenger = RecordingProviderMessenger(outcome: .success(.health(isTunnelRunning: true)))
    private let transparentProxyMessenger = RecordingProviderMessenger(
        outcome: .success(.health(isTunnelRunning: true)))
    private let slots = SlotSelectingTunnelController(
        packetTunnel: FakeSystemTunnelController(),
        transparentProxy: FakeSystemTunnelController()
    )

    @Test
    func sendsToTheTransparentProxyWhileItsSlotIsSelected() async throws {
        let browsing = try ConnectionTestTunnels.named("Browsing")
            .routed(by: RoutingPolicy(mode: .selectedApplications(ApplicationSelection([]))))
        try await slots.install(browsing)

        _ = try await messenger().send(.healthCheck)

        #expect(await transparentProxyMessenger.requests == [.healthCheck])
        #expect(await packetTunnelMessenger.requests.isEmpty)
    }

    @Test
    func sendsToThePacketTunnelOtherwise() async throws {
        _ = try await messenger().send(.healthCheck)

        #expect(await packetTunnelMessenger.requests == [.healthCheck])
        #expect(await transparentProxyMessenger.requests.isEmpty)
    }

    private func messenger() -> SlotSelectingMessenger {
        SlotSelectingMessenger(
            selection: slots,
            packetTunnel: packetTunnelMessenger,
            transparentProxy: transparentProxyMessenger
        )
    }
}
