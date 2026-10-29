import Darwin
import Dispatch
import PacketTunnel
import SharedKernel
import TunnelConfiguration
import TunnelEngine

public struct SystemEndpointResolver: EndpointResolver {
    private static let resolutionQueue = DispatchQueue(label: "Splitway.EndpointResolution", attributes: .concurrent)

    public init() {}

    public func resolve(_ endpoint: Endpoint) async throws(EndpointResolutionError) -> ResolvedEndpoint {
        let resolution = await withCheckedContinuation { continuation in
            Self.resolutionQueue.async {
                continuation.resume(returning: Self.resolveBlocking(endpoint))
            }
        }
        return try resolution.get()
    }

    private static func resolveBlocking(_ endpoint: Endpoint) -> Result<ResolvedEndpoint, EndpointResolutionError> {
        var hints = addrinfo()
        hints.ai_flags = AI_DEFAULT
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_DGRAM
        hints.ai_protocol = IPPROTO_UDP
        var results: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(hostText(of: endpoint), endpoint.port.description, &hints, &results) == 0, let results else {
            return .failure(.unresolvable)
        }
        defer { freeaddrinfo(results) }
        let addresses = sequence(first: results) { info in info.pointee.ai_next }.compactMap { info in
            SocketAddressReader.address(of: info.pointee)
        }
        guard let address = addresses.first(where: { address in address.family == .ipv4 }) ?? addresses.first else {
            return .failure(.unresolvable)
        }
        return .success(ResolvedEndpoint(address: address, port: endpoint.port))
    }

    private static func hostText(of endpoint: Endpoint) -> String {
        switch endpoint.host {
        case .address(let address): address.description
        case .name(let name): name.description
        }
    }
}
