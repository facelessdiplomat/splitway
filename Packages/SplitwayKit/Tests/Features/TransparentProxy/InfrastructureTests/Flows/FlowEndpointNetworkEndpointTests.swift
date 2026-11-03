import Foundation
import Network
import SharedKernel
import Testing
import TransparentProxy
import TransparentProxyInfrastructure

@Suite
struct FlowEndpointNetworkEndpointTests {
    @Test(arguments: ["203.0.113.7", "2001:db8::1"])
    func convertsAnAddressEndpointBothWays(address: String) throws {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(address), port: 443)

        let flowEndpoint = try #require(FlowEndpoint(endpoint))

        #expect(
            flowEndpoint == FlowEndpoint(address: try SharedKernel.IPAddress(address), port: try NetworkPort(443)))
        #expect(flowEndpoint.networkEndpoint == endpoint)
    }

    @Test
    func leavesOutEndpointsWithoutAnAddress() throws {
        let named = NWEndpoint.hostPort(host: .name("example.com", nil), port: 443)
        let byURL = NWEndpoint.url(try #require(URL(string: "https://example.com")))

        #expect(FlowEndpoint(named) == nil)
        #expect(FlowEndpoint(byURL) == nil)
    }
}
