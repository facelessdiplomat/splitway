import AppRouting
import AppRoutingTestSupport
import Dispatch
import Foundation
import PacketTunnel
import SharedKernel
import SharedKernelTestSupport
import Testing
import TransparentProxy
import TransparentProxyTestSupport
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEngine
import TunnelEngineTestSupport
import TunnelLibrary

struct TransparentProxyTestEnvironment {
    static let browserProcess = ProcessInstance(identifier: 101, version: 1)
    static let mailProcess = ProcessInstance(identifier: 202, version: 1)
    static let endpointAddress = IPAddress.ipv4(0xC633_6401)

    static let identities: [ProcessInstance: CodeIdentity] = [
        Self.browserProcess: CodeIdentity(
            signingIdentifier: "com.example.browser",
            teamIdentifier: FlowRoutingFixtures.browserTeam,
            executablePath: "/Applications/Browser.app/Contents/MacOS/Browser",
            isSignedByApple: false
        ),
        Self.mailProcess: CodeIdentity(
            signingIdentifier: "com.example.mail",
            teamIdentifier: "MAIL123456",
            executablePath: "/Applications/Mail Client.app/Contents/MacOS/Mail Client",
            isSignedByApple: false
        ),
    ]

    let engine = InMemoryUserspaceNetworkEngine()
    let registry = TunnelRuntimeRegistry()
    let session: TransparentProxySession

    init() {
        session = TransparentProxySession(
            starter: TransparentProxyStarter(
                engine: engine,
                endpointResolution: ResolveTunnelEndpointsUseCase(
                    resolver: FixedEndpointResolver(address: Self.endpointAddress)
                ),
                registry: registry
            ),
            router: ProxiedFlowRouter(
                sourceResolver: SourceApplicationResolver(
                    reader: InMemoryCodeIdentityReader(identities: Self.identities)),
                environment: RelayEnvironment(
                    targetQueue: DispatchQueue(label: "TransparentProxyTests"),
                    clock: FixedWallClock(Date(timeIntervalSince1970: 1_793_268_900))
                )
            ),
            pathMonitor: SilentNetworkPathMonitor()
        )
    }

    static func tunnel(routing mode: RoutingMode) throws -> ActiveTunnel {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        return ActiveTunnel(
            id: TunnelIdentifier(),
            configuration: configuration,
            routingPolicy: RoutingPolicy(mode: mode)
        )
    }

    static func selectedBrowser() throws -> RoutingMode {
        .selectedApplications(
            ApplicationSelection([
                try ApplicationIdentity(
                    kind: .application,
                    displayName: "Browser",
                    path: "/Applications/Browser.app",
                    signingIdentifiers: ["com.example.browser"],
                    teamIdentifier: FlowRoutingFixtures.browserTeam
                )
            ])
        )
    }

    static func request(from process: ProcessInstance) throws -> ProxiedFlowRequest {
        ProxiedFlowRequest(
            auditToken: try AuditToken.fixture(processIdentifier: process.identifier, version: process.version),
            remoteEndpoint: FlowEndpoint(address: FlowRoutingFixtures.tunnelAddress, port: try NetworkPort(443)),
            remoteHostname: nil
        )
    }
}

struct FixedEndpointResolver: EndpointResolver {
    let address: IPAddress

    func resolve(_ endpoint: Endpoint) async throws(EndpointResolutionError) -> ResolvedEndpoint {
        ResolvedEndpoint(address: address, port: endpoint.port)
    }
}

struct SilentNetworkPathMonitor: NetworkPathMonitor {
    func pathUpdates() -> AsyncStream<NetworkPathStatus> {
        AsyncStream { continuation in continuation.finish() }
    }
}
