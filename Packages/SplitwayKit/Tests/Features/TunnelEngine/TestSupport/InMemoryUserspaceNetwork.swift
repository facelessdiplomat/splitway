import SharedKernel
import SharedKernelTestSupport
import TunnelEngine

public final class InMemoryUserspaceNetwork: RunningUserspaceNetwork {
    public struct Snapshot: Sendable {
        public var connections: [InMemoryUserspaceConnection] = []
        public var isStopped = false
    }

    public let state = AwaitableState(Snapshot())
    private let dialFailure: UserspaceNetworkError?
    private let resolvedAddresses: [IPAddress]

    public init(dialFailure: UserspaceNetworkError? = nil, resolvedAddresses: [IPAddress] = []) {
        self.dialFailure = dialFailure
        self.resolvedAddresses = resolvedAddresses
    }

    public func apply(_ configuration: UAPIConfiguration) throws(TunnelEngineError) {}

    public func runtimeStatistics() throws(TunnelEngineError) -> RuntimeStatistics {
        RuntimeStatistics(peers: [])
    }

    public func bumpSockets() throws(TunnelEngineError) {}

    public func stop() {
        state.update { snapshot in snapshot.isStopped = true }
    }

    public func dialTCP(
        to destination: UserspaceNetworkDestination,
        timeout: Duration
    ) throws(UserspaceNetworkError) -> any UserspaceConnection {
        try connection(to: destination)
    }

    public func openUDP(to destination: UserspaceNetworkDestination) throws(UserspaceNetworkError)
        -> any UserspaceConnection
    {
        try connection(to: destination)
    }

    public func lookUpAddresses(of name: DomainName, timeout: Duration) throws(UserspaceNetworkError) -> [IPAddress] {
        guard !resolvedAddresses.isEmpty else { throw .lookupFailed }
        return resolvedAddresses
    }

    private func connection(to destination: UserspaceNetworkDestination) throws(UserspaceNetworkError)
        -> InMemoryUserspaceConnection
    {
        if let dialFailure {
            throw dialFailure
        }
        let connection = InMemoryUserspaceConnection(destination: destination)
        state.update { snapshot in snapshot.connections.append(connection) }
        return connection
    }
}
