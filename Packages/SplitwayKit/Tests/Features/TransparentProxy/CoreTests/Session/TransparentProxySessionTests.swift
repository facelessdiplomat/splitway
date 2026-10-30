import AppRouting
import AppRoutingTestSupport
import Foundation
import SharedKernel
import Testing
import TransparentProxy
import TransparentProxyTestSupport
import TunnelEngine
import TunnelEngineTestSupport

@Suite
struct TransparentProxySessionTests {
    @Test
    func startsTheUserspaceNetworkAndReturnsTheRulesOfTheTunnel() async throws {
        let environment = TransparentProxyTestEnvironment()

        let plan = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )

        #expect(environment.engine.startedInterfaces.count == 1)
        #expect(plan.includedNetworks.contains(FlowRoutingFixtures.tunnelAddress))
        #expect(plan.excludedNetworks.contains(TransparentProxyTestEnvironment.endpointAddress))
        #expect(await environment.registry.currentNetwork != nil)
    }

    @Test
    func refusesATunnelThatTakesAllTraffic() async throws {
        let environment = TransparentProxyTestEnvironment()
        let tunnel = try TransparentProxyTestEnvironment.tunnel(routing: .allTraffic)

        await #expect(throws: TransparentProxyError.routingModeUnsupported) {
            try await environment.session.start(tunnel)
        }
        #expect(environment.engine.startedInterfaces.isEmpty)
    }

    @Test
    func sendsAStreamOfASelectedApplicationThroughTheTunnel() async throws {
        let environment = TransparentProxyTestEnvironment()
        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )

        let isHandled = environment.session.handleStream(
            ScriptedStreamFlow(),
            request: try TransparentProxyTestEnvironment.request(from: TransparentProxyTestEnvironment.browserProcess)
        )

        #expect(isHandled)
        await environment.engine.network.state.wait { snapshot in snapshot.connections.count == 1 }
    }

    @Test
    func leavesAStreamOfAnotherApplicationToTheSystem() async throws {
        let environment = TransparentProxyTestEnvironment()
        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )

        let isHandled = environment.session.handleStream(
            ScriptedStreamFlow(),
            request: try TransparentProxyTestEnvironment.request(from: TransparentProxyTestEnvironment.mailProcess)
        )

        #expect(!isHandled)
        #expect(environment.engine.network.state.update { snapshot in snapshot.connections.isEmpty })
    }

    @Test
    func recordsAStreamAttributedToAnotherNetworkExtension() async throws {
        let environment = TransparentProxyTestEnvironment()
        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )

        let isHandled = environment.session.handleStream(
            ScriptedStreamFlow(),
            request: try TransparentProxyTestEnvironment.request(
                from: TransparentProxyTestEnvironment.otherProxyProcess)
        )

        #expect(!isHandled)
        #expect(environment.attributionLog.networkExtensionPaths == [TransparentProxyTestEnvironment.otherProxyPath])
    }

    @Test
    func sendsDatagramsOfASelectedApplicationThroughTheTunnel() async throws {
        let environment = TransparentProxyTestEnvironment()
        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )
        let flow = ScriptedDatagramFlow()

        let isHandled = environment.session.handleDatagrams(
            flow,
            request: try TransparentProxyTestEnvironment.request(from: TransparentProxyTestEnvironment.browserProcess)
        )
        await flow.state.wait { snapshot in snapshot.isOpened }
        flow.send([
            ProxiedDatagram(
                payload: Data([1, 2, 3]),
                remoteEndpoint: FlowEndpoint(address: FlowRoutingFixtures.tunnelAddress, port: try NetworkPort(53))
            )
        ])

        #expect(isHandled)
        await environment.engine.network.state.wait { snapshot in snapshot.connections.count == 1 }
    }

    @Test
    func leavesFlowsToTheSystemBeforeTheStart() throws {
        let environment = TransparentProxyTestEnvironment()

        let isHandled = environment.session.handleStream(
            ScriptedStreamFlow(),
            request: try TransparentProxyTestEnvironment.request(from: TransparentProxyTestEnvironment.browserProcess)
        )

        #expect(!isHandled)
    }

    @Test
    func stoppingClosesTheRelaysAndTheNetwork() async throws {
        let environment = TransparentProxyTestEnvironment()
        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(routing: TransparentProxyTestEnvironment.selectedBrowser())
        )
        let flow = ScriptedStreamFlow()
        _ = environment.session.handleStream(
            flow,
            request: try TransparentProxyTestEnvironment.request(from: TransparentProxyTestEnvironment.browserProcess)
        )
        await flow.state.wait { snapshot in snapshot.isOpened }

        await environment.session.stop()

        await flow.state.wait { snapshot in !snapshot.readClosings.isEmpty }
        #expect(environment.engine.network.state.update { snapshot in snapshot.isStopped })
        #expect(await environment.registry.currentNetwork == nil)
    }
}
