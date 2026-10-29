import Foundation
import Testing
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelEngine
import TunnelLibrary

@Suite
struct ObserveConnectionStateUseCaseTests {
    private static let connectedMoment = Date(timeIntervalSince1970: 1_793_268_900)

    @Test
    func followsTheSystemThroughAUserEndedSession() async {
        let controller = FakeSystemTunnelController()
        let states = ObserveConnectionStateUseCase(controller: controller).execute()

        controller.emit(.connecting, .connected(since: Self.connectedMoment), .disconnecting, .disconnected)

        #expect(
            await Self.collect(4, from: states) == [
                .connecting, .connected(since: Self.connectedMoment), .disconnecting, .disconnected,
            ]
        )
    }

    @Test
    func showsTheReasonOfAnUnexpectedDisconnect() async {
        let controller = FakeSystemTunnelController(disconnectFailure: .engineFailed(.socketsUnavailable))
        let states = ObserveConnectionStateUseCase(controller: controller).execute()

        controller.emit(.connecting, .connected(since: Self.connectedMoment), .disconnected)

        #expect(
            await Self.collect(3, from: states) == [
                .connecting, .connected(since: Self.connectedMoment), .failed(.engineFailed(.socketsUnavailable)),
            ]
        )
    }

    @Test
    func keepsTheFailureUntilTheNextAttempt() async {
        let controller = FakeSystemTunnelController(disconnectFailure: .configurationUnavailable)
        let states = ObserveConnectionStateUseCase(controller: controller).execute()

        controller.emit(.connecting, .disconnected, .disconnected, .connecting)

        #expect(
            await Self.collect(4, from: states) == [
                .connecting, .failed(.configurationUnavailable), .failed(.configurationUnavailable), .connecting,
            ]
        )
    }

    @Test
    func treatsAnUnconfiguredSlotAsDisconnected() async {
        let controller = FakeSystemTunnelController(disconnectFailure: .startRejected)
        let states = ObserveConnectionStateUseCase(controller: controller).execute()

        controller.emit(.notConfigured)

        #expect(await Self.collect(1, from: states) == [.disconnected])
    }

    @Test
    func reportsWhichTunnelTheStateBelongsTo() async {
        let tunnel = TunnelIdentifier()
        let controller = FakeSystemTunnelController(installed: tunnel)
        let states = ObserveConnectionStateUseCase(controller: controller).execute()

        controller.emit(.connecting)

        var iterator = states.makeAsyncIterator()
        #expect(await iterator.next() == SlotState(tunnelID: tunnel, connection: .connecting))
    }

    @Test
    func showsEveryOtherTunnelAsDisconnected() {
        let tunnel = TunnelIdentifier()
        let state = SlotState(tunnelID: tunnel, connection: .connecting)

        #expect(state.connectionState(of: tunnel) == .connecting)
        #expect(state.connectionState(of: TunnelIdentifier()) == .disconnected)
    }

    private static func collect(_ count: Int, from states: AsyncStream<SlotState>) async -> [ConnectionState] {
        var collected: [ConnectionState] = []
        for await state in states.prefix(count) {
            collected.append(state.connection)
        }
        return collected
    }
}
