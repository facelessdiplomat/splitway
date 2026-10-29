import SharedKernel

public struct AllowedIPs: Sendable, Hashable {
    public let networks: [IPNetwork]

    public init(_ networks: [IPNetwork]) {
        self.networks = networks
    }

    public var networkSet: IPNetworkSet {
        IPNetworkSet(networks)
    }

    public var isEmpty: Bool {
        networks.isEmpty
    }
}
