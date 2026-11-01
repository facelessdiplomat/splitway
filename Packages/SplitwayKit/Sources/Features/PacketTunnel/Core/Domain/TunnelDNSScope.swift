import SharedKernel

public enum TunnelDNSScope: Sendable, Hashable {
    case allDomains
    case matchingDomains([DomainName])
}
