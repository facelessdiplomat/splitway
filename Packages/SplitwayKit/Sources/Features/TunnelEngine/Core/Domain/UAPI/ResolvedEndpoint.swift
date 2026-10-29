import SharedKernel

public struct ResolvedEndpoint: Sendable, Hashable {
    public let address: IPAddress
    public let port: NetworkPort

    public init(address: IPAddress, port: NetworkPort) {
        self.address = address
        self.port = port
    }

    var uapiText: String {
        switch address.family {
        case .ipv4: "\(address):\(port)"
        case .ipv6: "[\(address)]:\(port)"
        }
    }
}
