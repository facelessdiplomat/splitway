import DNSProxy
import Foundation
import Testing
import TransparentProxy
import TransparentProxyTestSupport

@Suite
struct DNSRefusalRelayTests {
    static let query: [UInt8] =
        [0x12, 0x34, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        + [0x07] + Array("example".utf8) + [0x03] + Array("com".utf8) + [0x00]
        + [0x00, 0x01, 0x00, 0x01]

    @Test
    func answersEachQueryWithARefusalFromTheOriginalResolver() async throws {
        let flow = ScriptedDatagramFlow()
        let resolver = try RelayFixtures.endpoint(53, port: 53)
        Self.relay(flow: flow).start(onFinish: {})

        flow.send([ProxiedDatagram(payload: Data(Self.query), remoteEndpoint: resolver)])

        await flow.state.wait { snapshot in !snapshot.writtenDatagrams.isEmpty }
        let refusal = try DNSRefusalResponseBuilder.response(refusing: Self.query)
        #expect(
            flow.state.current.writtenDatagrams == [ProxiedDatagram(payload: Data(refusal), remoteEndpoint: resolver)])
    }

    @Test
    func skipsADatagramThatIsNotADNSQuery() async throws {
        let flow = ScriptedDatagramFlow()
        let resolver = try RelayFixtures.endpoint(53, port: 53)
        Self.relay(flow: flow).start(onFinish: {})

        flow.send([
            ProxiedDatagram(payload: Data([0x01, 0x02]), remoteEndpoint: resolver),
            ProxiedDatagram(payload: Data(Self.query), remoteEndpoint: resolver),
        ])

        await flow.state.wait { snapshot in !snapshot.writtenDatagrams.isEmpty }
        #expect(flow.state.current.writtenDatagrams.count == 1)
    }

    @Test
    func closesTheFlowWhenTheApplicationClosesIt() async {
        let (flow, finished) = (ScriptedDatagramFlow(), FinishSignal())
        Self.relay(flow: flow).start(onFinish: finished.callAsFunction)

        flow.closeFromTheApp()

        await finished.wait()
        #expect(flow.state.current.readClosings == [nil])
    }

    @Test
    func cancellingClosesTheFlow() async {
        let (flow, finished) = (ScriptedDatagramFlow(), FinishSignal())
        let relay = Self.relay(flow: flow)
        relay.start(onFinish: finished.callAsFunction)

        relay.cancel()

        await finished.wait()
        #expect(flow.state.current.readClosings == [.aborted])
    }

    @Test
    func closesAnIdleFlow() async throws {
        let (flow, finished) = (ScriptedDatagramFlow(), FinishSignal())
        let policy = try UDPRelayPolicy(
            datagramBufferByteCount: 1_500, idleTimeout: .seconds(60), maximumAssociations: 4)
        let relay = DNSRefusalRelay(flow: flow, policy: policy, environment: RelayFixtures.environment())
        relay.start(onFinish: finished.callAsFunction)

        let closesEarly = relay.closeIfIdle(at: RelayFixtures.start.addingTimeInterval(59))
        let closesOnTime = relay.closeIfIdle(at: RelayFixtures.start.addingTimeInterval(60))

        #expect(!closesEarly)
        #expect(closesOnTime)
        await finished.wait()
    }

    private static func relay(flow: ScriptedDatagramFlow) -> DNSRefusalRelay {
        DNSRefusalRelay(flow: flow, policy: .standard, environment: RelayFixtures.environment())
    }
}
