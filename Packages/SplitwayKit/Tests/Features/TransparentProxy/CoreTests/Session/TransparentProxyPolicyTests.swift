import AppRouting
import Testing
import TransparentProxy
import TransparentProxyTestSupport

@Suite
struct TransparentProxyPolicyTests {
    @Test
    func appliesANewSelectionToNewFlows() async throws {
        let environment = TransparentProxyTestEnvironment()
        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )
        let mailBefore = try Self.handlesStream(from: TransparentProxyTestEnvironment.mailProcess, in: environment)

        try environment.session.apply(RoutingPolicy(mode: TransparentProxyTestEnvironment.selectedMail()))

        #expect(!mailBefore)
        #expect(try Self.handlesStream(from: TransparentProxyTestEnvironment.mailProcess, in: environment))
        #expect(try !Self.handlesStream(from: TransparentProxyTestEnvironment.browserProcess, in: environment))
    }

    @Test
    func refusesAPolicyOfAnotherMode() async throws {
        let environment = TransparentProxyTestEnvironment()
        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )

        #expect(throws: TransparentProxyError.routingModeUnsupported) {
            try environment.session.apply(RoutingPolicy(mode: .allTraffic))
        }
        #expect(try Self.handlesStream(from: TransparentProxyTestEnvironment.browserProcess, in: environment))
    }

    @Test
    func refusesAPolicyBeforeTheStart() throws {
        let environment = TransparentProxyTestEnvironment()

        #expect(throws: TransparentProxyError.notRunning) {
            try environment.session.apply(RoutingPolicy(mode: TransparentProxyTestEnvironment.selectedBrowser()))
        }
    }

    private static func handlesStream(
        from process: ProcessInstance,
        in environment: TransparentProxyTestEnvironment
    ) throws -> Bool {
        environment.session.handleStream(
            ScriptedStreamFlow(),
            request: try TransparentProxyTestEnvironment.request(from: process)
        )
    }
}
