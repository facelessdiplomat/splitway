import Foundation
import Testing
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary

@Suite
struct ReadSlotStateUseCaseTests {
    private static let connectedMoment = Date(timeIntervalSince1970: 1_793_268_900)

    @Test
    func readsTheInstalledTunnelAndItsConnection() async {
        let office = TunnelIdentifier()
        let controller = FakeSystemTunnelController(
            installed: office,
            status: .connected(since: Self.connectedMoment)
        )

        let slot = await ReadSlotStateUseCase(controller: controller).execute()

        #expect(slot == SlotState(tunnelID: office, connection: .connected(since: Self.connectedMoment)))
    }

    @Test
    func readsASlotWithoutConfigurationAsDisconnected() async {
        let controller = FakeSystemTunnelController(status: .notConfigured)

        let slot = await ReadSlotStateUseCase(controller: controller).execute()

        #expect(slot == .empty)
    }
}
