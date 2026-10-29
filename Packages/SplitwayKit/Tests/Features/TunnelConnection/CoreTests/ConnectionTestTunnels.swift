import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelLibrary

enum ConnectionTestTunnels {
    static func named(_ name: String) throws -> Tunnel {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        return Tunnel(name: try TunnelName(name), configuration: configuration)
    }
}
