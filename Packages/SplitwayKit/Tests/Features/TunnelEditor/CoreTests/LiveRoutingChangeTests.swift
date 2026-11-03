import AppRouting
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEditor
import TunnelLibrary

@Suite
struct LiveRoutingChangeTests {
    private static let applications = RoutingPolicy(mode: .selectedApplications(ApplicationSelection([])))

    @Test
    func appliesANewSelectionOfAnUnchangedTunnelLive() throws {
        let tunnel = try Self.tunnel(routedBy: Self.applications)
        let selection = RoutingPolicy(mode: .selectedApplications(ApplicationSelection([try Self.browser()])))

        #expect(LiveRoutingChange.isPossible(from: tunnel, to: tunnel.configuration, routedBy: selection))
    }

    @Test
    func needsARestartWhenTheConfigurationChanges() throws {
        let tunnel = try Self.tunnel(routedBy: Self.applications)
        let changed = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.multiplePeers).configuration)

        #expect(!LiveRoutingChange.isPossible(from: tunnel, to: changed, routedBy: Self.applications))
        #expect(!LiveRoutingChange.isPossible(from: tunnel, to: nil, routedBy: Self.applications))
    }

    @Test
    func needsARestartWhenTheModeChanges() throws {
        let allTraffic = try Self.tunnel(routedBy: .default)
        let applications = try Self.tunnel(routedBy: Self.applications)

        #expect(
            !LiveRoutingChange.isPossible(from: allTraffic, to: allTraffic.configuration, routedBy: Self.applications))
        #expect(!LiveRoutingChange.isPossible(from: applications, to: applications.configuration, routedBy: .default))
    }

    private static func tunnel(routedBy policy: RoutingPolicy) throws -> Tunnel {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        return Tunnel(name: try TunnelName("Browsing"), configuration: configuration, routingPolicy: policy)
    }

    private static func browser() throws -> ApplicationIdentity {
        try ApplicationIdentity(kind: .application, displayName: "Browser", path: "/Applications/Browser.app")
    }
}
