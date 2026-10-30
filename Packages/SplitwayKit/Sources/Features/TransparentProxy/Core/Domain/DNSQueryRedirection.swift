import DNSProxy
import SharedKernel
import TunnelConfiguration

public struct DNSQueryRedirection: Sendable, Hashable {
    private static let dnsPort: UInt16 = 53

    private let resolver: IPAddress?

    public init(for configuration: TunnelConfiguration) {
        resolver = DNSUpstreamSelection(for: configuration)?.servers.first
    }

    public var redirectsQueries: Bool {
        resolver != nil
    }

    public func target(for endpoint: FlowEndpoint) -> FlowEndpoint {
        guard let resolver, endpoint.port.value == Self.dnsPort else { return endpoint }
        return FlowEndpoint(address: resolver, port: endpoint.port)
    }
}
