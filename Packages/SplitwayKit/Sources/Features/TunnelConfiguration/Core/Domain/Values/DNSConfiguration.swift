import SharedKernel

public struct DNSConfiguration: Sendable, Hashable {
    public let servers: [IPAddress]
    public let searchDomains: [DomainName]

    public init(servers: [IPAddress] = [], searchDomains: [DomainName] = []) {
        self.servers = servers
        self.searchDomains = searchDomains
    }

    public init(entries: [String]) throws(DNSConfigurationParsingError) {
        var servers: [IPAddress] = []
        var searchDomains: [DomainName] = []
        for entry in entries {
            if let server = try? IPAddress(entry) {
                servers.append(server)
            } else if let searchDomain = try? DomainName(entry) {
                searchDomains.append(searchDomain)
            } else {
                throw .invalidEntry(entry)
            }
        }
        self.init(servers: servers, searchDomains: searchDomains)
    }

    public var isEmpty: Bool {
        servers.isEmpty && searchDomains.isEmpty
    }

    public var entries: [String] {
        servers.map(\.description) + searchDomains.map(\.description)
    }
}
