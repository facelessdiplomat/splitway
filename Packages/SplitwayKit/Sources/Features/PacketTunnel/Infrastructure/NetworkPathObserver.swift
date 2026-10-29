import Dispatch
import Network
import PacketTunnel

public struct NetworkPathObserver: NetworkPathMonitor {
    public init() {}

    public func pathUpdates() -> AsyncStream<NetworkPathStatus> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied ? .available : .unavailable)
            }
            continuation.onTermination = { _ in monitor.cancel() }
            monitor.start(queue: DispatchQueue(label: "Splitway.NetworkPath"))
        }
    }
}
