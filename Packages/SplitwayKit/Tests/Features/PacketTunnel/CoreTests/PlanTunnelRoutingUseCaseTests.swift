import AppRouting
import PacketTunnel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct PlanTunnelRoutingUseCaseTests {
    @Test
    func routesAllTrafficThroughTheNetworkPlanOfTheConfiguration() throws {
        let configuration = try Self.configuration(WgQuickFixtures.minimal)

        let routing = try PlanTunnelRoutingUseCase().execute(configuration: configuration, policy: .default)

        #expect(routing.mode == .allTraffic)
        #expect(routing.networkPlan == (try TunnelNetworkPlanner.plan(for: configuration, routedBy: .default)))
    }

    @Test
    func leavesSelectedApplicationsToTheTransparentProxy() throws {
        let configuration = try Self.configuration(WgQuickFixtures.minimal)
        let policy = RoutingPolicy(mode: .selectedApplications(ApplicationSelection([])))

        #expect(throws: PacketTunnelError.invalidNetworkPlan(.routingModeNotSupported(.selectedApplications))) {
            try PlanTunnelRoutingUseCase().execute(configuration: configuration, policy: policy)
        }
    }

    private static func configuration(_ text: String) throws -> TunnelConfiguration {
        try #require(WgQuickConfigurationParser.parse(text).configuration)
    }
}
