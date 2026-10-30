import Foundation
import SharedKernel
import SharedKernelTestSupport
import Testing
import TransparentProxy
import TransparentProxyTestSupport
import TunnelEngine
import TunnelEngineTestSupport

@Suite(.timeLimit(.minutes(1)))
struct TCPFlowRelayTests {
    @Test
    func relaysTheBytesOfTheAppToTheTunnelInOrder() async throws {
        let (flow, network) = (ScriptedStreamFlow(), InMemoryUserspaceNetwork())
        try Self.relay(flow: flow, network: network).start(onFinish: {})

        flow.send(Array("hello".utf8))
        flow.send(Array(" world".utf8))

        let connection = await RelayFixtures.connection(0, of: network)
        await connection.state.wait { snapshot in snapshot.writtenBytes.count >= 11 }
        #expect(connection.state.current.writtenBytes == Array("hello world".utf8))
        #expect(connection.destination == RelayFixtures.destination(of: try RelayFixtures.endpoint(2)))
    }

    @Test
    func relaysTheBytesOfTheTunnelToTheAppInOrder() async throws {
        let (flow, network) = (ScriptedStreamFlow(), InMemoryUserspaceNetwork())
        try Self.relay(flow: flow, network: network).start(onFinish: {})
        let connection = await Self.receivingConnection(of: network)

        connection.deliver(Array("abc".utf8))
        connection.deliver(Array("def".utf8))

        await flow.state.wait { snapshot in snapshot.writtenBytes.count >= 6 }
        #expect(flow.state.current.writtenBytes == Array("abcdef".utf8))
    }

    @Test
    func returnsCreditOnlyAfterTheAppAcceptedTheBytes() async throws {
        let (flow, network) = (ScriptedStreamFlow(holdsWrites: true), InMemoryUserspaceNetwork())
        try Self.relay(flow: flow, network: network).start(onFinish: {})
        let connection = await Self.receivingConnection(of: network)

        connection.deliver(Array("abc".utf8))
        let grantedBeforeTheAppAccepted = connection.state.current.grantedByteCount
        flow.releaseHeldWrites()

        #expect(grantedBeforeTheAppAccepted == 0)
        await connection.state.wait { snapshot in snapshot.grantedByteCount == 3 }
    }

    @Test
    func receivesFromTheTunnelInChunksWithAWindowOfSeveralChunks() async throws {
        let (flow, network) = (ScriptedStreamFlow(), InMemoryUserspaceNetwork())
        let policy = try TCPRelayPolicy(chunkByteCount: 1_024, connectTimeout: .seconds(5), idleTimeout: .seconds(60))
        try Self.relay(flow: flow, network: network, policy: policy).start(onFinish: {})

        let connection = await Self.receivingConnection(of: network)

        #expect(connection.state.current.readByteCount == 1_024)
        #expect(connection.state.current.initialCredit == 1_024 * TCPFlowRelay.windowChunkCount)
    }

    @Test
    func halfClosesTheTunnelSideWhenTheAppStopsSending() async throws {
        let (flow, network) = (ScriptedStreamFlow(), InMemoryUserspaceNetwork())
        try Self.relay(flow: flow, network: network).start(onFinish: {})

        flow.endStream()

        let connection = await RelayFixtures.connection(0, of: network)
        await connection.state.wait { snapshot in snapshot.closings == [.write] }
        #expect(flow.state.current.writeClosings.isEmpty)
    }

    @Test
    func closesTheAppWriteSideOnceTheTunnelEndsAndPendingWritesComplete() async throws {
        let (flow, network) = (ScriptedStreamFlow(holdsWrites: true), InMemoryUserspaceNetwork())
        try Self.relay(flow: flow, network: network).start(onFinish: {})
        let connection = await Self.receivingConnection(of: network)

        connection.deliver(Array("abc".utf8))
        connection.finishReceiving(with: nil)
        let closingsBeforeTheWriteCompleted = flow.state.current.writeClosings
        flow.releaseHeldWrites()

        #expect(closingsBeforeTheWriteCompleted.isEmpty)
        await flow.state.wait { snapshot in snapshot.writeClosings == [nil] }
    }

    @Test
    func finishesOnceBothSidesEnd() async throws {
        let (flow, network, finished) = (ScriptedStreamFlow(), InMemoryUserspaceNetwork(), FinishSignal())
        try Self.relay(flow: flow, network: network).start(onFinish: finished.callAsFunction)
        let connection = await Self.receivingConnection(of: network)

        flow.endStream()
        connection.finishReceiving(with: nil)

        await finished.wait()
        #expect(connection.state.current.closings.last == .both)
        #expect(flow.state.current.readClosings == [nil])
        #expect(flow.state.current.writeClosings == [nil])
    }

    @Test
    func resetsTheAppConnectionWhenTheTunnelFailsMidTransfer() async throws {
        let (flow, network, finished) = (ScriptedStreamFlow(), InMemoryUserspaceNetwork(), FinishSignal())
        try Self.relay(flow: flow, network: network).start(onFinish: finished.callAsFunction)
        let connection = await Self.receivingConnection(of: network)

        connection.finishReceiving(with: .connectionFailed)

        await finished.wait()
        #expect(flow.state.current.readClosings == [.peerReset])
        #expect(flow.state.current.writeClosings == [.peerReset])
        #expect(connection.state.current.closings.last == .both)
    }

    @Test
    func closesTheTunnelSideWhenTheAppFailsMidTransfer() async throws {
        let (flow, network, finished) = (ScriptedStreamFlow(), InMemoryUserspaceNetwork(), FinishSignal())
        try Self.relay(flow: flow, network: network).start(onFinish: finished.callAsFunction)
        let connection = await Self.receivingConnection(of: network)

        flow.fail(.peerReset)

        await finished.wait()
        #expect(connection.state.current.closings.last == .both)
    }

    @Test(arguments: [
        (UserspaceNetworkError.connectionFailed, ProxiedFlowError.refused),
        (UserspaceNetworkError.timedOut, ProxiedFlowError.timedOut),
        (UserspaceNetworkError.networkStopped, ProxiedFlowError.aborted),
    ])
    func refusesTheAppConnectionWhenTheTunnelCannotConnect(
        failure: UserspaceNetworkError,
        reported: ProxiedFlowError
    ) async throws {
        let flow = ScriptedStreamFlow()
        let (network, finished) = (InMemoryUserspaceNetwork(dialFailure: failure), FinishSignal())
        try Self.relay(flow: flow, network: network).start(onFinish: finished.callAsFunction)

        await finished.wait()

        #expect(!flow.state.current.isOpened)
        #expect(flow.state.current.readClosings == [reported])
        #expect(flow.state.current.writeClosings == [reported])
    }

    @Test
    func closesARelayThatStayedIdleForTheIdleTimeout() async throws {
        let (flow, network, finished) = (ScriptedStreamFlow(), InMemoryUserspaceNetwork(), FinishSignal())
        let policy = try TCPRelayPolicy(chunkByteCount: 1_024, connectTimeout: .seconds(5), idleTimeout: .seconds(60))
        let relay = try Self.relay(flow: flow, network: network, policy: policy)
        relay.start(onFinish: finished.callAsFunction)
        _ = await Self.receivingConnection(of: network)

        let closesEarly = relay.closeIfIdle(at: RelayFixtures.start.addingTimeInterval(59))
        let closesOnTime = relay.closeIfIdle(at: RelayFixtures.start.addingTimeInterval(60))

        #expect(!closesEarly)
        #expect(closesOnTime)
        await finished.wait()
        #expect(flow.state.current.readClosings == [.timedOut])
    }

    @Test
    func abortsBothSidesWhenCancelled() async throws {
        let (flow, network, finished) = (ScriptedStreamFlow(), InMemoryUserspaceNetwork(), FinishSignal())
        let relay = try Self.relay(flow: flow, network: network)
        relay.start(onFinish: finished.callAsFunction)
        let connection = await Self.receivingConnection(of: network)

        relay.cancel()

        await finished.wait()
        #expect(flow.state.current.writeClosings == [.aborted])
        #expect(connection.state.current.closings.last == .both)
    }

    private static func relay(
        flow: ScriptedStreamFlow,
        network: InMemoryUserspaceNetwork,
        policy: TCPRelayPolicy = .standard
    ) throws -> TCPFlowRelay {
        TCPFlowRelay(
            flow: flow,
            destination: RelayFixtures.destination(of: try RelayFixtures.endpoint(2)),
            network: network,
            policy: policy,
            environment: RelayFixtures.environment()
        )
    }

    private static func receivingConnection(of network: InMemoryUserspaceNetwork) async -> InMemoryUserspaceConnection {
        let connection = await RelayFixtures.connection(0, of: network)
        await connection.state.wait { snapshot in snapshot.receiver != nil }
        return connection
    }
}
