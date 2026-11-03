import SharedKernel

public struct TunnelDNSPlan: Sendable, Hashable {
    public let servers: [IPAddress]
    public let searchDomains: [DomainName]

    public init(servers: [IPAddress], searchDomains: [DomainName]) {
        self.servers = servers
        self.searchDomains = searchDomains
    }
}
