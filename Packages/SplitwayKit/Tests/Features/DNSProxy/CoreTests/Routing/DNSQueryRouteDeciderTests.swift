import AppRouting
import AppRoutingTestSupport
import DNSProxy
import Testing

@Suite
struct DNSQueryRouteDeciderTests {
    struct RouteCase: Sendable, CustomTestStringConvertible {
        let name: String
        let source: SourceApplication
        let tunnel: TunnelReadiness
        let whenTunnelUnavailable: TunnelUnavailableBehavior
        let resolvesNamesThroughTunnel: Bool
        let route: DNSQueryRoute

        init(
            _ name: String,
            source: SourceApplication,
            tunnel: TunnelReadiness = .ready(carriesIPv6: false),
            whenTunnelUnavailable: TunnelUnavailableBehavior = .block,
            resolvesNamesThroughTunnel: Bool = true,
            route: DNSQueryRoute
        ) {
            self.name = name
            self.source = source
            self.tunnel = tunnel
            self.whenTunnelUnavailable = whenTunnelUnavailable
            self.resolvesNamesThroughTunnel = resolvesNamesThroughTunnel
            self.route = route
        }

        var testDescription: String {
            name
        }
    }

    static let unknownSource = SourceApplication(signingIdentifier: nil, teamIdentifier: nil, executablePath: nil)

    static let cases: [RouteCase] = [
        RouteCase("selected application", source: FlowRoutingFixtures.browser, route: .throughTunnel),
        RouteCase(
            "helper of the selected application", source: FlowRoutingFixtures.browserHelper, route: .throughTunnel),
        RouteCase(
            "selected application while the tunnel is down and blocks",
            source: FlowRoutingFixtures.browser,
            tunnel: .unavailable,
            route: .refuse
        ),
        RouteCase(
            "selected application while the tunnel is down and bypasses",
            source: FlowRoutingFixtures.browser,
            tunnel: .unavailable,
            whenTunnelUnavailable: .bypass,
            route: .toOriginalResolver
        ),
        RouteCase(
            "application that is not selected", source: FlowRoutingFixtures.otherApplication, route: .toOriginalResolver
        ),
        RouteCase(
            "application that is not selected while the tunnel is down",
            source: FlowRoutingFixtures.otherApplication,
            tunnel: .unavailable,
            route: .toOriginalResolver
        ),
        RouteCase("unknown source", source: unknownSource, route: .toOriginalResolver),
        RouteCase(
            "unknown source while the tunnel is down", source: unknownSource, tunnel: .unavailable,
            route: .toOriginalResolver
        ),
        RouteCase(
            "selected application without a DNS server in the tunnel",
            source: FlowRoutingFixtures.browser,
            resolvesNamesThroughTunnel: false,
            route: .toOriginalResolver
        ),
        RouteCase(
            "selected application without a DNS server while the tunnel is down and blocks",
            source: FlowRoutingFixtures.browser,
            tunnel: .unavailable,
            resolvesNamesThroughTunnel: false,
            route: .refuse
        ),
    ]

    @Test(arguments: cases)
    func routesTheQueryBySourceAndTunnelState(routeCase: RouteCase) throws {
        let snapshot = try FlowRoutingFixtures.snapshot(whenTunnelUnavailable: routeCase.whenTunnelUnavailable)
        let decider = DNSQueryRouteDecider(
            snapshot: snapshot,
            resolvesNamesThroughTunnel: routeCase.resolvesNamesThroughTunnel
        )

        let route = decider.route(for: routeCase.source, tunnel: routeCase.tunnel)

        #expect(route == routeCase.route)
    }
}
