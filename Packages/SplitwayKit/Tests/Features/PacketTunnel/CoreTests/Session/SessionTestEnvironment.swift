import AppRouting
import PacketTunnel
import ServiceCatalog
import ServiceCatalogTestSupport
import SharedKernel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEngine

struct SessionTestEnvironment {
    static let endpoint = "vpn.example.com:51820"

    let log = SessionEventLog()
    let resolver: FakeEndpointResolver
    let device: FakeWireGuardDevice
    let session: PacketTunnelSession
    let configuration: TunnelConfiguration

    init(
        tunnelDescriptor: Int32? = 7,
        engineFailure: TunnelEngineError? = nil,
        serviceRoutingFailure: TunnelEngineError? = nil,
        services: [ServiceProfile] = []
    ) throws {
        resolver = FakeEndpointResolver(log: log)
        device = FakeWireGuardDevice(
            log: log, startFailure: engineFailure, serviceRoutingFailure: serviceRoutingFailure)
        session = PacketTunnelSession(
            engine: device,
            interfaceLocator: FakeTunnelInterfaceLocator(log: log, descriptor: tunnelDescriptor),
            endpointResolver: resolver,
            pathMonitor: SilentNetworkPathMonitor(),
            routingPlanner: PlanTunnelRoutingUseCase(
                serviceCatalog: LoadServiceCatalogUseCase(
                    bundled: FixedBundledServiceCatalog(services: services),
                    custom: InMemoryCustomServiceRepository()
                )
            )
        )
        configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        resolver.answer(Self.endpoint, with: try Self.resolvedEndpoint("203.0.113.5"))
    }

    static func resolvedEndpoint(_ address: String) throws -> ResolvedEndpoint {
        ResolvedEndpoint(address: try IPAddress(address), port: try NetworkPort(51820))
    }

    static func policy(selecting services: [ServiceProfile]) -> RoutingPolicy {
        RoutingPolicy(mode: .selectedServices(ServiceSelection(services.map(\.id))))
    }

    func start(routedBy policy: RoutingPolicy = .default) async throws {
        let preparedStart = try await session.prepareStart(configuration: configuration, routedBy: policy)
        log.record(.appliedSettings)
        try await session.completeStart(preparedStart)
    }
}
