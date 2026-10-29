import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelConnection
import TunnelLibrary

@Suite
struct TunnelSlotDescriptionTests {
    @Test
    func showsTheFirstPeerEndpointAsTheServer() throws {
        let tunnel = try ConnectionTestTunnels.named("Office")

        #expect(TunnelSlotDescription.serverAddress(for: tunnel) == "vpn.example.com:51820")
    }

    @Test
    func fallsBackToTheTunnelNameWithoutEndpoints() throws {
        let fixture = WgQuickFixtures.minimal.replacingOccurrences(of: "Endpoint = vpn.example.com:51820\n", with: "")
            .replacingOccurrences(of: "Endpoint = vpn.example.com:51820", with: "")
        let configuration = try #require(WgQuickConfigurationParser.parse(fixture).configuration)
        let tunnel = Tunnel(name: try TunnelName("Office"), configuration: configuration)

        #expect(TunnelSlotDescription.serverAddress(for: tunnel) == "Office")
    }
}
