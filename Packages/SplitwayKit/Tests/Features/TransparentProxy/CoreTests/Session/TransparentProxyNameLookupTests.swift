import DNSProxyTestSupport
import Foundation
import SharedKernel
import Testing
import TransparentProxy
import TransparentProxyTestSupport
import TunnelEngine
import TunnelEngineTestSupport

@Suite(.timeLimit(.minutes(1)))
struct TransparentProxyNameLookupTests {
    static let hostname = "example.com"
    static let answeredAddress = IPAddress.ipv4(0xC000_020A)
    static let lookedUpAddress = IPAddress.ipv4(0xC000_0263)

    @Test
    func connectsToAnAddressTheTunnelResolverAnsweredWithoutLookingItUp() async throws {
        let network = InMemoryUserspaceNetwork(resolvedAddresses: [Self.lookedUpAddress])
        let environment = try await Self.startedEnvironment(with: network)
        try await Self.answer(Self.hostname, with: Self.answeredAddress, in: environment)

        let isHandled = environment.session.handleStream(
            ScriptedStreamFlow(), request: try Self.stream(to: Self.answeredAddress))

        #expect(isHandled)
        await network.state.wait { snapshot in snapshot.connections.count == 2 }
        #expect(network.state.current.connections.last?.destination == (try Self.destination(Self.answeredAddress)))
        #expect(network.state.current.lookedUpNames.isEmpty)
    }

    @Test
    func looksUpANameWhoseAddressCameFromOutsideTheTunnel() async throws {
        let network = InMemoryUserspaceNetwork(resolvedAddresses: [Self.lookedUpAddress])
        let environment = try await Self.startedEnvironment(with: network)

        _ = environment.session.handleStream(ScriptedStreamFlow(), request: try Self.stream(to: Self.answeredAddress))

        await network.state.wait { snapshot in snapshot.connections.count == 1 }
        #expect(network.state.current.connections.first?.destination == (try Self.destination(Self.lookedUpAddress)))
        #expect(network.state.current.lookedUpNames == [try DomainName(Self.hostname)])
    }

    @Test
    func reusesItsOwnLookupForTheNextStreamToTheSameName() async throws {
        let network = InMemoryUserspaceNetwork(resolvedAddresses: [Self.lookedUpAddress])
        let environment = try await Self.startedEnvironment(with: network)

        _ = environment.session.handleStream(ScriptedStreamFlow(), request: try Self.stream(to: Self.answeredAddress))
        await network.state.wait { snapshot in snapshot.connections.count == 1 }
        _ = environment.session.handleStream(ScriptedStreamFlow(), request: try Self.stream(to: Self.answeredAddress))

        await network.state.wait { snapshot in snapshot.connections.count == 2 }
        #expect(network.state.current.lookedUpNames.count == 1)
        #expect(network.state.current.connections.last?.destination == (try Self.destination(Self.lookedUpAddress)))
    }

    private static func startedEnvironment(with network: InMemoryUserspaceNetwork) async throws
        -> TransparentProxyTestEnvironment
    {
        let environment = TransparentProxyTestEnvironment(network: network)
        _ = try await environment.session.start(
            TransparentProxyTestEnvironment.tunnel(
                routing: TransparentProxyTestEnvironment.selectedBrowser(),
                configuration: TransparentProxyTestEnvironment.tunnelWithItsOwnResolver()
            )
        )
        return environment
    }

    private static func answer(
        _ name: String,
        with address: IPAddress,
        in environment: TransparentProxyTestEnvironment
    ) async throws {
        let flow = ScriptedDatagramFlow()
        let resolver = try TransparentProxyTestEnvironment.systemResolver()
        _ = environment.session.handleDatagrams(
            flow,
            request: try TransparentProxyTestEnvironment.dnsQuery(from: TransparentProxyTestEnvironment.browserProcess)
        )
        await flow.state.wait { snapshot in snapshot.isOpened }
        flow.send([ProxiedDatagram(payload: Data(DNSResponseFixture.query(for: name)), remoteEndpoint: resolver)])
        let network = environment.engine.network
        await network.state.wait { snapshot in !snapshot.connections.isEmpty }
        let association = try #require(network.state.current.connections.first)
        await association.state.wait { snapshot in snapshot.receiver != nil }

        association.deliver(DNSResponseFixture.response(to: name, answers: [.address(address, timeToLive: 300)]))

        await flow.state.wait { snapshot in !snapshot.writtenDatagrams.isEmpty }
    }

    private static func stream(to address: IPAddress) throws -> ProxiedFlowRequest {
        let process = TransparentProxyTestEnvironment.browserProcess
        return ProxiedFlowRequest(
            auditToken: try AuditToken.fixture(processIdentifier: process.identifier, version: process.version),
            remoteEndpoint: FlowEndpoint(address: address, port: try NetworkPort(443)),
            remoteHostname: hostname
        )
    }

    private static func destination(_ address: IPAddress) throws -> UserspaceNetworkDestination {
        UserspaceNetworkDestination(address: address, port: try NetworkPort(443))
    }
}
