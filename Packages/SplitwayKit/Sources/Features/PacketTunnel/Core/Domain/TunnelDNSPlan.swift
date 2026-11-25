import SharedKernel

public struct TunnelDNSPlan: Sendable, Hashable {
    public let servers: [IPAddress]
    public let searchDomains: [DomainName]
    public let scope: TunnelDNSScope

    public init(servers: [IPAddress], searchDomains: [DomainName], scope: TunnelDNSScope) {
        self.servers = servers
        self.searchDomains = searchDomains
        self.scope = scope
    }
}
