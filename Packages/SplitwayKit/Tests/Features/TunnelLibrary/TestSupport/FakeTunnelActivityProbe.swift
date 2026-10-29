import TunnelLibrary

public actor FakeTunnelActivityProbe: TunnelActivityProbe {
    public private(set) var stoppedTunnels: [TunnelIdentifier] = []
    private var activeTunnels: Set<TunnelIdentifier>
    private let stopSucceeds: Bool

    public init(activeTunnels: Set<TunnelIdentifier> = [], stopSucceeds: Bool = true) {
        self.activeTunnels = activeTunnels
        self.stopSucceeds = stopSucceeds
    }

    public func isActive(_ tunnel: TunnelIdentifier) async -> Bool {
        activeTunnels.contains(tunnel)
    }

    public func stop(_ tunnel: TunnelIdentifier) async throws(TunnelActivityError) {
        guard stopSucceeds else { throw .stopFailed }
        activeTunnels.remove(tunnel)
        stoppedTunnels.append(tunnel)
    }
}
