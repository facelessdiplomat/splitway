import PacketTunnel
import PacketTunnelInfrastructure
import SharedKernel
import Testing
import TunnelConfiguration

@Suite
struct SystemEndpointResolverTests {
    private let resolver = SystemEndpointResolver()

    @Test(arguments: [
        ("203.0.113.5:51820", "203.0.113.5"),
        ("[2001:db8::5]:51820", "2001:db8::5"),
    ])
    func resolvesAddressLiteralsWithoutAskingTheNetwork(endpoint: String, address: String) async throws {
        let resolved = try await resolver.resolve(try Endpoint(endpoint))

        #expect(resolved.address == (try IPAddress(address)))
        #expect(resolved.port == (try NetworkPort(51820)))
    }

    @Test
    func resolvesLocalNamesFromTheHostsFile() async throws {
        let resolved = try await resolver.resolve(try Endpoint("localhost:51820"))

        #expect(resolved.address.isLoopback)
    }
}
