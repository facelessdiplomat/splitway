import AppRouting
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelLibrary

@Suite
struct TunnelTests {
    @Test
    func startsWithTheDefaultRoutingPolicy() throws {
        let tunnel = try sampleTunnel()

        #expect(tunnel.routingPolicy == .default)
    }

    @Test
    func keepsItsIdentityWhenRenamedOrReconfigured() throws {
        let tunnel = try sampleTunnel()
        let newConfiguration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.full).configuration)
        let newPolicy = RoutingPolicy(mode: .allTraffic, whenTunnelUnavailable: .bypass)

        let changed =
            tunnel
            .renamed(to: try TunnelName("Prague"))
            .reconfigured(with: newConfiguration)
            .routed(by: newPolicy)

        #expect(changed.id == tunnel.id)
        #expect(changed.name.description == "Prague")
        #expect(changed.configuration == newConfiguration)
        #expect(changed.routingPolicy == newPolicy)
    }

    @Test
    func generatesDistinctIdentifiers() {
        #expect(TunnelIdentifier() != TunnelIdentifier())
    }

    private func sampleTunnel() throws -> Tunnel {
        Tunnel(
            name: try TunnelName("Office"),
            configuration: try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        )
    }
}
