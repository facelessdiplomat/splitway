import AppRouting
import Testing

@Suite
struct FlowRoutingPerformanceTests {
    private static let flowCount = 1_000_000
    private static let budget = Duration.seconds(5)

    @Test
    func decidesAMillionFlowsWithinTheBudget() throws {
        let decider = FlowRoutingDecider(snapshot: try FlowRoutingFixtures.snapshot())
        let flows = [
            FlowRoutingFixtures.browser, FlowRoutingFixtures.otherApplication, FlowRoutingFixtures.unsignedCurl,
        ]
        .map { source in
            FlowDescriptor(
                source: source, destination: .address(FlowRoutingFixtures.tunnelAddress), port: 443, transport: .tcp)
        }
        var tunnelledFlows = 0

        let elapsed = ContinuousClock().measure {
            for index in 0..<Self.flowCount
            where decider.decision(for: flows[index % flows.count], tunnel: .ready(carriesIPv6: true)) == .tunnel {
                tunnelledFlows += 1
            }
        }

        #expect(tunnelledFlows == Self.flowCount * 2 / 3 + 1)
        #expect(elapsed < Self.budget, "A million decisions took \(elapsed)")
    }
}
