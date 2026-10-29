import SharedKernel

public enum EndpointHost: Sendable, Hashable {
    case address(IPAddress)
    case name(DomainName)
}
