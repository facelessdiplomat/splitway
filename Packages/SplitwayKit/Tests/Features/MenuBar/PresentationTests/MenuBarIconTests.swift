import Foundation
import MenuBarPresentation
import Testing
import TunnelLibraryPresentation

@Suite
struct MenuBarIconTests {
    static let connectedSinceNoon = Date(timeIntervalSince1970: 1_800_000_000)

    @Test(arguments: [
        ([TunnelRowStatus](), MenuBarIcon.disconnected),
        ([.disconnected, .disconnected], .disconnected),
        ([.unavailable], .disconnected),
        ([.connecting], .connecting),
        ([.reconnecting], .connecting),
        ([.disconnecting], .connecting),
        ([.connected(since: connectedSinceNoon)], .connected),
        ([.failed(.permissionDenied)], .failed),
        ([.failed(.permissionDenied), .connected(since: connectedSinceNoon)], .connected),
        ([.failed(.permissionDenied), .connecting], .connecting),
    ])
    func showsTheStateOfTheTunnels(statuses: [TunnelRowStatus], icon: MenuBarIcon) {
        #expect(MenuBarIcon(statuses: statuses) == icon)
    }
}
