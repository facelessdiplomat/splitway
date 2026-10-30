import SharedKernel

public protocol RunningUserspaceNetwork: RunningWireGuardDevice {
    func dialTCP(
        to destination: UserspaceNetworkDestination,
        timeout: Duration
    ) throws(UserspaceNetworkError) -> any UserspaceConnection

    func openUDP(to destination: UserspaceNetworkDestination) throws(UserspaceNetworkError) -> any UserspaceConnection

    func lookUpAddresses(of name: DomainName, timeout: Duration) throws(UserspaceNetworkError) -> [IPAddress]
}
