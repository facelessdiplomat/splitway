import Synchronization
import TunnelEngine

public final class InMemoryUserspaceNetworkEngine: UserspaceNetworkEngine {
    public let network: InMemoryUserspaceNetwork
    private let startFailure: TunnelEngineError?
    private let starts = Mutex<[UserspaceNetworkInterface]>([])

    public init(
        network: InMemoryUserspaceNetwork = InMemoryUserspaceNetwork(),
        startFailure: TunnelEngineError? = nil
    ) {
        self.network = network
        self.startFailure = startFailure
    }

    public var startedInterfaces: [UserspaceNetworkInterface] {
        starts.withLock { interfaces in interfaces }
    }

    public func startNetwork(
        configuration: UAPIConfiguration,
        interface: UserspaceNetworkInterface
    ) throws(TunnelEngineError) -> any RunningUserspaceNetwork {
        if let startFailure {
            throw startFailure
        }
        starts.withLock { interfaces in interfaces.append(interface) }
        return network
    }
}
