import TunnelConnection

public struct RefreshTunnelControlUseCase: Sendable {
    private let observeConnection: ObserveConnectionStateUseCase
    private let refresher: any TunnelControlRefresher

    public init(observeConnection: ObserveConnectionStateUseCase, refresher: any TunnelControlRefresher) {
        self.observeConnection = observeConnection
        self.refresher = refresher
    }

    public func execute() async {
        for await _ in observeConnection.execute() {
            await refresher.refresh()
        }
    }
}
