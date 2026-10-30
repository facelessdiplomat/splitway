import SharedKernel

public struct UserspaceNetworkDestination: Sendable, Hashable {
    public let address: IPAddress
    public let port: NetworkPort

    public init(address: IPAddress, port: NetworkPort) {
        self.address = address
        self.port = port
    }
}
