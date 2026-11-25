import ControlWidgets
import Testing
import TunnelConnection
import TunnelConnectionTestSupport

@Suite(.timeLimit(.minutes(1)))
struct RefreshTunnelControlUseCaseTests {
    @Test
    func refreshesTheControlOnEveryConnectionChange() async {
        let controller = FakeSystemTunnelController()
        let refresher = StreamingTunnelControlRefresher()
        let refresh = RefreshTunnelControlUseCase(
            observeConnection: ObserveConnectionStateUseCase(controller: controller),
            refresher: refresher
        )
        var refreshes = refresher.refreshes.makeAsyncIterator()
        let observation = Task { await refresh.execute() }

        controller.emit(.connecting)
        let refreshAfterConnecting: Void? = await refreshes.next()
        controller.emit(.disconnected)
        let refreshAfterDisconnecting: Void? = await refreshes.next()
        observation.cancel()

        #expect(refreshAfterConnecting != nil)
        #expect(refreshAfterDisconnecting != nil)
    }
}

private struct StreamingTunnelControlRefresher: TunnelControlRefresher {
    let refreshes: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init() {
        (refreshes, continuation) = AsyncStream.makeStream()
    }

    func refresh() async {
        continuation.yield()
    }
}
