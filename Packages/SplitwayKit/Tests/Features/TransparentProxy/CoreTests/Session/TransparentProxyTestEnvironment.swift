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
    static let otherProxyProcess = ProcessInstance(identifier: 303, version: 1)
    static let otherProxyPath =
        "/Library/SystemExtensions/7F3A2B10-4C5D-4E6F-8A9B-0C1D2E3F4A5B/com.example.proxy.systemextension"
        + "/Contents/MacOS/com.example.proxy"
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
        Self.otherProxyProcess: CodeIdentity(
            signingIdentifier: "com.example.proxy",
            teamIdentifier: "PROXY12345",
            executablePath: Self.otherProxyPath,
            isSignedByApple: false
        ),
    ]

    let engine = InMemoryUserspaceNetworkEngine()
    let attributionLog = RecordingSuspiciousAttributionLog()
    let session: TransparentProxySession

    init() {
        session = TransparentProxySession(
            starter: TransparentProxyStarter(
                engine: engine,
                endpointResolution: ResolveTunnelEndpointsUseCase(
                    resolver: FixedEndpointResolver(address: Self.endpointAddress)
                )
            ),
            router: ProxiedFlowRouter(
                sourceResolver: SourceApplicationResolver(
                    reader: InMemoryCodeIdentityReader(identities: Self.identities)),
                attribution: SuspiciousAttributionMonitor(log: attributionLog),
                environment: RelayEnvironment(
                    targetQueue: DispatchQueue(label: "TransparentProxyTests"),
                    clock: FixedWallClock(Date(timeIntervalSince1970: 1_793_268_900))
                )
            ),
            pathMonitor: SilentNetworkPathMonitor()
        )
    }

    static func tunnel(routing mode: RoutingMode, configuration: TunnelConfiguration? = nil) throws -> ActiveTunnel {
        let minimal = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        return ActiveTunnel(
            id: TunnelIdentifier(),
            configuration: configuration ?? minimal,
            routingPolicy: RoutingPolicy(mode: mode)
        )
    }

    static func tunnelWithItsOwnResolver() throws -> TunnelConfiguration {
        try ProxyTestConfigurations.configuration(allowedIPs: "192.0.2.0/24", dnsServers: "192.0.2.53")
    }

    static func resolverOfTheTunnel() throws -> UserspaceNetworkDestination {
        UserspaceNetworkDestination(address: try IPAddress("192.0.2.53"), port: try NetworkPort(53))
    }

    static func systemResolver() throws -> FlowEndpoint {
        FlowEndpoint(address: .ipv4(0xC0A8_4001), port: try NetworkPort(53))
    }

    static func dnsQuery(from process: ProcessInstance) throws -> ProxiedFlowRequest {
        ProxiedFlowRequest(
            auditToken: try AuditToken.fixture(processIdentifier: process.identifier, version: process.version),
            remoteEndpoint: try systemResolver(),
            remoteHostname: nil
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
