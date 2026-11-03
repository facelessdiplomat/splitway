import SharedKernel
import TunnelCoreFramework
import TunnelEngine

final class TunnelCoreUserspaceNetwork: RunningUserspaceNetwork {
    private static let addressSeparator: Character = "\n"

    private let handle: Int32
    private let device: TunnelCoreWireGuardDevice

    init(handle: Int32) {
        self.handle = handle
        device = TunnelCoreWireGuardDevice(handle: handle)
    }

    func apply(_ configuration: UAPIConfiguration) throws(TunnelEngineError) {
        try device.apply(configuration)
    }

    func runtimeStatistics() throws(TunnelEngineError) -> RuntimeStatistics {
        try device.runtimeStatistics()
    }

    func bumpSockets() throws(TunnelEngineError) {
        try device.bumpSockets()
    }

    func stop() {
        device.stop()
    }

    func dialTCP(
        to destination: UserspaceNetworkDestination,
        timeout: Duration
    ) throws(UserspaceNetworkError) -> any UserspaceConnection {
        var connection: Int32 = 0
        let status = String(describing: destination.address).withCString { address in
            tc_usernet_dial_tcp(handle, address, destination.port.value, timeout.wholeMilliseconds, &connection)
        }
        try UserspaceNetworkError.check(status, whenHandleIsReleased: .networkStopped)
        return TunnelCoreUserspaceConnection(handle: connection)
    }

    func openUDP(to destination: UserspaceNetworkDestination) throws(UserspaceNetworkError)
        -> any UserspaceConnection
    {
        var connection: Int32 = 0
        let status = String(describing: destination.address).withCString { address in
            tc_usernet_dial_udp(handle, address, destination.port.value, &connection)
        }
        try UserspaceNetworkError.check(status, whenHandleIsReleased: .networkStopped)
        return TunnelCoreUserspaceConnection(handle: connection)
    }

    func lookUpAddresses(of name: DomainName, timeout: Duration) throws(UserspaceNetworkError) -> [IPAddress] {
        var response: UnsafeMutablePointer<CChar>?
        let status = String(describing: name).withCString { text in
            tc_usernet_lookup_host(handle, text, timeout.wholeMilliseconds, &response)
        }
        try UserspaceNetworkError.check(status, whenHandleIsReleased: .networkStopped)
        guard let response else { throw .internalFailure }
        defer { tc_free(response) }
        return String(cString: response).split(separator: Self.addressSeparator).compactMap { line in
            try? IPAddress(String(line))
        }
    }
}
