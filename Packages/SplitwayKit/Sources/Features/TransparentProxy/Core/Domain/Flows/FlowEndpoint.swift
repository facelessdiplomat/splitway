import SharedKernel

public struct FlowEndpoint: Sendable, Hashable {
    public let address: IPAddress
    public let port: NetworkPort

    public init(address: IPAddress, port: NetworkPort) {
        self.address = address
        self.port = port
    }
}
