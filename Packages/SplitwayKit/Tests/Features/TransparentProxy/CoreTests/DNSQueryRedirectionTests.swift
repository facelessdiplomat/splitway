import SharedKernel
import Testing
import TransparentProxy

@Suite
struct DNSQueryRedirectionTests {
    private static let systemResolver = IPAddress.ipv4(0xC0A8_4001)

    @Test
    func sendsQueriesToTheDNSServerOfTheTunnel() throws {
        let redirection = DNSQueryRedirection(
            for: try ProxyTestConfigurations.configuration(allowedIPs: "192.0.2.0/24", dnsServers: "192.0.2.53")
        )

        let target = redirection.target(for: try Self.query(to: Self.systemResolver))

        #expect(redirection.redirectsQueries)
        #expect(target == FlowEndpoint(address: try IPAddress("192.0.2.53"), port: try NetworkPort(53)))
    }

    @Test
    func sendsQueriesToAPublicResolverThroughATunnelWithoutDNSServers() throws {
        let redirection = DNSQueryRedirection(for: try ProxyTestConfigurations.configuration(allowedIPs: "0.0.0.0/0"))

        let target = redirection.target(for: try Self.query(to: Self.systemResolver))

        #expect(target == FlowEndpoint(address: try IPAddress("1.1.1.1"), port: try NetworkPort(53)))
    }

    @Test
    func leavesQueriesAloneWhenTheTunnelCarriesNoResolver() throws {
        let redirection = DNSQueryRedirection(for: try ProxyTestConfigurations.configuration(allowedIPs: "10.0.0.0/8"))
        let query = try Self.query(to: Self.systemResolver)

        let target = redirection.target(for: query)

        #expect(!redirection.redirectsQueries)
        #expect(target == query)
    }

    @Test
    func leavesConnectionsToOtherPortsAlone() throws {
        let redirection = DNSQueryRedirection(
            for: try ProxyTestConfigurations.configuration(allowedIPs: "0.0.0.0/0", dnsServers: "192.0.2.53")
        )
        let connection = FlowEndpoint(address: Self.systemResolver, port: try NetworkPort(443))

        let target = redirection.target(for: connection)

        #expect(target == connection)
    }

    @Test
    func belongsToThePlanOfTheTunnel() throws {
        let configuration = try ProxyTestConfigurations.configuration(
            allowedIPs: "192.0.2.0/24", dnsServers: "192.0.2.53")

        let plan = TransparentProxyNetworkPlan(for: configuration, resolvedEndpointAddresses: [])

        #expect(plan.dnsRedirection == DNSQueryRedirection(for: configuration))
    }

    private static func query(to resolver: IPAddress) throws -> FlowEndpoint {
        FlowEndpoint(address: resolver, port: try NetworkPort(53))
    }
}
