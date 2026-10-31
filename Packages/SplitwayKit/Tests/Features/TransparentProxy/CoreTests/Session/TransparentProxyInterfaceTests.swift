import Testing
import TransparentProxy
import TunnelConfiguration

@Suite
struct TransparentProxyInterfaceTests {
    @Test
    func startsTheUserspaceNetworkWithRoomForWireGuardOnThePath() async throws {
        let environment = TransparentProxyTestEnvironment(pathMTU: 1_280)

        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )

        #expect(environment.engine.startedInterfaces.map(\.mtu) == [try MTU(1_200)])
    }
}
