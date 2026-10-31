import AppRouting
import AppRoutingTestSupport
import SharedKernel
import Testing

@Suite
struct FlowRoutingDeciderTests {
    struct DecisionCase: Sendable, CustomTestStringConvertible {
        let name: String
        let source: SourceApplication
        let destination: FlowDestination
        let tunnel: TunnelReadiness
        let whenTunnelUnavailable: TunnelUnavailableBehavior
        let decision: FlowRouteDecision

        init(
            _ name: String,
            source: SourceApplication,
            destination: FlowDestination = .address(FlowRoutingFixtures.tunnelAddress),
            tunnel: TunnelReadiness = .ready(carriesIPv6: true),
            whenTunnelUnavailable: TunnelUnavailableBehavior = .block,
            decision: FlowRouteDecision
        ) {
            self.name = name
            self.source = source
            self.destination = destination
            self.tunnel = tunnel
            self.whenTunnelUnavailable = whenTunnelUnavailable
            self.decision = decision
        }

        var testDescription: String {
            name
        }
    }

    static let cases: [DecisionCase] = [
        DecisionCase("selected application", source: FlowRoutingFixtures.browser, decision: .tunnel),
        DecisionCase(
            "application that is not selected", source: FlowRoutingFixtures.otherApplication, decision: .direct),
        DecisionCase(
            "helper of the selected application", source: FlowRoutingFixtures.browserHelper, decision: .tunnel),
        DecisionCase(
            "selected identifier signed by another team",
            source: FlowRoutingFixtures.spoofedBrowser,
            decision: .direct
        ),
        DecisionCase(
            "Apple identifier signed by a developer team",
            source: FlowRoutingFixtures.spoofedCurl,
            decision: .direct
        ),
        DecisionCase(
            "destination outside the tunnel networks",
            source: FlowRoutingFixtures.browser,
            destination: .address(FlowRoutingFixtures.outsideAddress),
            decision: .direct
        ),
        DecisionCase(
            "unavailable tunnel that blocks",
            source: FlowRoutingFixtures.browser,
            tunnel: .unavailable,
            decision: .block
        ),
        DecisionCase(
            "unavailable tunnel that lets traffic through",
            source: FlowRoutingFixtures.browser,
            tunnel: .unavailable,
            whenTunnelUnavailable: .bypass,
            decision: .direct
        ),
        DecisionCase(
            "IPv6 destination of a tunnel without IPv6",
            source: FlowRoutingFixtures.browser,
            destination: .address(FlowRoutingFixtures.tunnelIPv6Address),
            tunnel: .ready(carriesIPv6: false),
            decision: .block
        ),
        DecisionCase(
            "IPv6 destination of a tunnel with IPv6",
            source: FlowRoutingFixtures.browser,
            destination: .address(FlowRoutingFixtures.tunnelIPv6Address),
            decision: .tunnel
        ),
        DecisionCase(
            "command-line tool found by its path", source: FlowRoutingFixtures.unsignedCurl, decision: .tunnel),
        DecisionCase(
            "unsigned executable inside the selected bundle",
            source: FlowRoutingFixtures.bundledExecutable,
            decision: .tunnel
        ),
        DecisionCase(
            "executable next to the selected bundle",
            source: FlowRoutingFixtures.neighbourExecutable,
            decision: .direct
        ),
        DecisionCase(
            "selected application that already exited",
            source: FlowRoutingFixtures.exitedBrowser,
            decision: .tunnel
        ),
        DecisionCase(
            "selected application that already exited, unavailable tunnel",
            source: FlowRoutingFixtures.exitedBrowser,
            tunnel: .unavailable,
            decision: .block
        ),
        DecisionCase(
            "application that already exited and is not selected",
            source: FlowRoutingFixtures.exitedMail,
            decision: .direct
        ),
        DecisionCase(
            "readable code that claims the identifier of a selected application",
            source: FlowRoutingFixtures.readableToolClaimingTheBrowser,
            decision: .direct
        ),
        DecisionCase(
            "tool launched by the selected application",
            source: FlowRoutingFixtures.appleGit.launched(by: [FlowRoutingFixtures.browser]),
            decision: .tunnel
        ),
        DecisionCase(
            "tool launched through a shell of the selected application",
            source: FlowRoutingFixtures.appleGit.launched(by: [
                FlowRoutingFixtures.appleShell, FlowRoutingFixtures.browser,
            ]),
            decision: .tunnel
        ),
        DecisionCase(
            "agent outside the bundle launched by a helper of the selected application",
            source: FlowRoutingFixtures.agentOutsideTheBundle.launched(by: [
                FlowRoutingFixtures.bundledExecutable, FlowRoutingFixtures.browser,
            ]),
            decision: .tunnel
        ),
        DecisionCase(
            "agent outside the bundle that nothing selected launched",
            source: FlowRoutingFixtures.agentOutsideTheBundle,
            decision: .direct
        ),
        DecisionCase(
            "tool launched by an application that is not selected",
            source: FlowRoutingFixtures.appleGit.launched(by: [FlowRoutingFixtures.otherApplication]),
            decision: .direct
        ),
        DecisionCase(
            "tool launched by code that claims the selected identifier",
            source: FlowRoutingFixtures.appleGit.launched(by: [FlowRoutingFixtures.spoofedBrowser]),
            decision: .direct
        ),
        DecisionCase(
            "tool launched by the selected application, unavailable tunnel",
            source: FlowRoutingFixtures.appleGit.launched(by: [FlowRoutingFixtures.browser]),
            tunnel: .unavailable,
            decision: .block
        ),
        DecisionCase(
            "destination given by host name",
            source: FlowRoutingFixtures.browser,
            destination: .hostname("example.com"),
            decision: .tunnel
        ),
    ]

    @Test(arguments: cases)
    func routesEveryFlowByItsSourceAndDestination(flow: DecisionCase) throws {
        let decider = FlowRoutingDecider(
            snapshot: try FlowRoutingFixtures.snapshot(whenTunnelUnavailable: flow.whenTunnelUnavailable)
        )

        let decision = decider.decision(
            for: FlowDescriptor(source: flow.source, destination: flow.destination, port: 443, transport: .tcp),
            tunnel: flow.tunnel
        )

        #expect(decision == flow.decision)
    }
}
