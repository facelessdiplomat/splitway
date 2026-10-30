import Foundation
import SharedKernel
import SharedKernelTestSupport
import Testing
import TransparentProxy
import TransparentProxyTestSupport
import TunnelEngine
import TunnelEngineTestSupport

@Suite(.timeLimit(.minutes(1)))
struct UDPFlowRelayTests {
    @Test
    func relaysDatagramsToTheirEndpointsAndRepliesBack() async throws {
        let (flow, network) = (ScriptedDatagramFlow(), InMemoryUserspaceNetwork())
        let (first, second) = (try RelayFixtures.endpoint(7), try RelayFixtures.endpoint(8))
        try Self.relay(flow: flow, network: network).start(onFinish: {})

        flow.send([Self.datagram("one", to: first), Self.datagram("two", to: second)])

        let firstConnection = await Self.receivingConnection(0, of: network)
        let secondConnection = await Self.receivingConnection(1, of: network)
        #expect(firstConnection.destination == RelayFixtures.destination(of: first))
        #expect(firstConnection.state.current.writtenChunks == [Array("one".utf8)])
        #expect(secondConnection.state.current.writtenChunks == [Array("two".utf8)])
        secondConnection.deliver(Array("reply".utf8))
        await flow.state.wait { snapshot in snapshot.writtenDatagrams == [Self.datagram("reply", to: second)] }
    }

    @Test
    func reusesTheAssociationOfAKnownEndpoint() async throws {
        let (flow, network) = (ScriptedDatagramFlow(), InMemoryUserspaceNetwork())
        let endpoint = try RelayFixtures.endpoint(7)
        try Self.relay(flow: flow, network: network).start(onFinish: {})

        flow.send([Self.datagram("one", to: endpoint)])
        flow.send([Self.datagram("two", to: endpoint)])

        let connection = await RelayFixtures.connection(0, of: network)
        await connection.state.wait { snapshot in snapshot.writtenChunks.count == 2 }
        #expect(network.state.current.connections.count == 1)
    }

    @Test
    func sendsDatagramsWhereTheCallerRoutesThemAndAnswersFromTheOriginalEndpoint() async throws {
        let (flow, network) = (ScriptedDatagramFlow(), InMemoryUserspaceNetwork())
        let (queried, tunnelResolver) = (
            try RelayFixtures.endpoint(53, port: 53), try RelayFixtures.endpoint(99, port: 53)
        )
        let relay = UDPFlowRelay(
            flow: flow,
            network: network,
            policy: .standard,
            environment: RelayFixtures.environment(),
            destination: { _ in RelayFixtures.destination(of: tunnelResolver) }
        )
        relay.start(onFinish: {})

        flow.send([Self.datagram("query", to: queried)])

        let connection = await Self.receivingConnection(0, of: network)
        #expect(connection.destination == RelayFixtures.destination(of: tunnelResolver))
        connection.deliver(Array("answer".utf8))
        await flow.state.wait { snapshot in snapshot.writtenDatagrams == [Self.datagram("answer", to: queried)] }
    }

    @Test
    func dropsDatagramsThatHaveNoRoute() async throws {
        let (flow, network) = (ScriptedDatagramFlow(), InMemoryUserspaceNetwork())
        let (unrouted, routed) = (try RelayFixtures.endpoint(7), try RelayFixtures.endpoint(8))
        let relay = UDPFlowRelay(
            flow: flow,
            network: network,
            policy: .standard,
            environment: RelayFixtures.environment(),
            destination: { endpoint in endpoint == unrouted ? nil : RelayFixtures.destination(of: endpoint) }
        )
        relay.start(onFinish: {})

        flow.send([Self.datagram("lost", to: unrouted), Self.datagram("kept", to: routed)])

        let connection = await RelayFixtures.connection(0, of: network)
        await connection.state.wait { snapshot in snapshot.writtenChunks.count == 1 }
        #expect(connection.destination == RelayFixtures.destination(of: routed))
        #expect(network.state.current.connections.count == 1)
    }

    @Test
    func closesTheLeastRecentlyActiveAssociationWhenFull() async throws {
        let (flow, network) = (ScriptedDatagramFlow(), InMemoryUserspaceNetwork())
        let policy = try UDPRelayPolicy(
            datagramBufferByteCount: 1_500, idleTimeout: .seconds(60), maximumAssociations: 1)
        try Self.relay(flow: flow, network: network, policy: policy).start(onFinish: {})

        flow.send([Self.datagram("one", to: try RelayFixtures.endpoint(7))])
        let first = await RelayFixtures.connection(0, of: network)
        flow.send([Self.datagram("two", to: try RelayFixtures.endpoint(8))])

        await first.state.wait { snapshot in snapshot.closings == [.both] }
    }

    @Test
    func closesIdleAssociationsAndThenTheIdleFlow() async throws {
        let (flow, network, finished) = (ScriptedDatagramFlow(), InMemoryUserspaceNetwork(), FinishSignal())
        let policy = try UDPRelayPolicy(
            datagramBufferByteCount: 1_500, idleTimeout: .seconds(60), maximumAssociations: 4)
        let relay = try Self.relay(flow: flow, network: network, policy: policy)
        relay.start(onFinish: finished.callAsFunction)
        flow.send([Self.datagram("one", to: try RelayFixtures.endpoint(7))])
        let connection = await Self.receivingConnection(0, of: network)

        let closesEarly = relay.closeIfIdle(at: RelayFixtures.start.addingTimeInterval(59))
        let closesOnTime = relay.closeIfIdle(at: RelayFixtures.start.addingTimeInterval(60))

        #expect(!closesEarly)
        #expect(closesOnTime)
        await finished.wait()
        #expect(connection.state.current.closings == [.both])
        #expect(flow.state.current.readClosings == [nil])
    }

    @Test
    func closesEveryAssociationWhenTheAppClosesTheFlow() async throws {
        let (flow, network, finished) = (ScriptedDatagramFlow(), InMemoryUserspaceNetwork(), FinishSignal())
        try Self.relay(flow: flow, network: network).start(onFinish: finished.callAsFunction)
        flow.send([Self.datagram("one", to: try RelayFixtures.endpoint(7))])
        let connection = await Self.receivingConnection(0, of: network)

        flow.closeFromTheApp()

        await finished.wait()
        #expect(connection.state.current.closings == [.both])
    }

    @Test
    func returnsCreditOnlyAfterTheAppAcceptedAReply() async throws {
        let (flow, network) = (ScriptedDatagramFlow(holdsWrites: true), InMemoryUserspaceNetwork())
        try Self.relay(flow: flow, network: network).start(onFinish: {})
        flow.send([Self.datagram("one", to: try RelayFixtures.endpoint(7))])
        let connection = await Self.receivingConnection(0, of: network)

        connection.deliver(Array("reply".utf8))
        let grantedBeforeTheAppAccepted = connection.state.current.grantedByteCount
        flow.releaseHeldWrites()

        #expect(grantedBeforeTheAppAccepted == 0)
        await connection.state.wait { snapshot in snapshot.grantedByteCount == 5 }
    }

    private static func relay(
        flow: ScriptedDatagramFlow,
        network: InMemoryUserspaceNetwork,
        policy: UDPRelayPolicy = .standard
    ) throws -> UDPFlowRelay {
        UDPFlowRelay(
            flow: flow,
            network: network,
            policy: policy,
            environment: RelayFixtures.environment(),
            destination: { endpoint in RelayFixtures.destination(of: endpoint) }
        )
    }

    private static func datagram(_ text: String, to endpoint: FlowEndpoint) -> ProxiedDatagram {
        ProxiedDatagram(payload: Data(text.utf8), remoteEndpoint: endpoint)
    }

    private static func receivingConnection(_ index: Int, of network: InMemoryUserspaceNetwork) async
        -> InMemoryUserspaceConnection
    {
        let connection = await RelayFixtures.connection(index, of: network)
        await connection.state.wait { snapshot in snapshot.receiver != nil && !snapshot.writtenChunks.isEmpty }
        return connection
    }
}
