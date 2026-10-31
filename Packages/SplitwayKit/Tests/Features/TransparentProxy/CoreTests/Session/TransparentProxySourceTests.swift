import Testing
import TransparentProxy
import TransparentProxyTestSupport
import TunnelEngineTestSupport

@Suite(.timeLimit(.minutes(1)))
struct TransparentProxySourceTests {
    static let exitedProcess = ProcessInstance(identifier: 404, version: 1)

    @Test
    func sendsAStreamOfASelectedApplicationThatAlreadyExitedThroughTheTunnel() async throws {
        let environment = TransparentProxyTestEnvironment()
        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )

        let isHandled = environment.session.handleStream(
            ScriptedStreamFlow(), request: try Self.request(signedAs: "com.example.browser"))

        #expect(isHandled)
        await environment.engine.network.state.wait { snapshot in snapshot.connections.count == 1 }
    }

    @Test
    func leavesAStreamOfAnotherApplicationThatAlreadyExitedToTheSystem() async throws {
        let environment = TransparentProxyTestEnvironment()
        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )

        let isHandled = environment.session.handleStream(
            ScriptedStreamFlow(), request: try Self.request(signedAs: "com.example.mail"))

        #expect(!isHandled)
    }

    private static func request(signedAs signingIdentifier: String) throws -> ProxiedFlowRequest {
        let request = try TransparentProxyTestEnvironment.request(from: exitedProcess)
        return ProxiedFlowRequest(
            auditToken: request.auditToken,
            remoteEndpoint: request.remoteEndpoint,
            remoteHostname: request.remoteHostname,
            signingIdentifier: signingIdentifier
        )
    }
}
