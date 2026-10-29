import PacketTunnel

struct SilentNetworkPathMonitor: NetworkPathMonitor {
    func pathUpdates() -> AsyncStream<NetworkPathStatus> {
        AsyncStream { _ in }
    }
}
