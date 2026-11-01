import AppRouting
import PacketTunnel
import ServiceCatalog
import ServiceCatalogTestSupport
import SharedKernel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEngine

@Suite
struct PlanTunnelRoutingUseCaseTests {
    @Test
    func routesAllTrafficWithoutTranslatingAddresses() async throws {
        let configuration = try Self.configuration(WgQuickFixtures.minimal)

        let routing = try await Self.planner(services: []).execute(configuration: configuration, policy: .default)

        #expect(routing.mode == .allTraffic)
        #expect(routing.networkPlan == (try TunnelNetworkPlanner.plan(for: configuration, routedBy: .default)))
        #expect(routing.translation == nil)
    }

    @Test
    func routesTheSelectedServicesThroughFakeAddresses() async throws {
        let configuration = try Self.configuration(WgQuickFixtures.commercialProviderStyle)
        let telegram = try ServiceCatalogFixtures.profile(
            id: "telegram", name: "Telegram", domains: ["telegram.org"], networks: ["91.108.4.0/22"])
        let policy = RoutingPolicy(mode: .selectedServices(ServiceSelection([telegram.id])))

        let routing = try await Self.planner(services: [telegram]).execute(configuration: configuration, policy: policy)

        #expect(routing.mode == .selectedServices)
        #expect(
            routing.translation
                == ServiceRoutingTranslation(
                    virtualResolver: try IPAddress("198.18.0.2"),
                    upstreamResolver: try IPAddress("192.0.2.53"),
                    fakeIPv4Network: .ipv4BenchmarkingRange,
                    fakeIPv6Network: nil
                )
        )
        #expect(routing.networkPlan.ipv4?.includedRoutes == [try IPNetwork("91.108.4.0/22"), .ipv4BenchmarkingRange])
        #expect(routing.networkPlan.dns?.scope == .matchingDomains([try DomainName("telegram.org")]))
    }

    @Test
    func leavesSelectedApplicationsToTheTransparentProxy() async throws {
        let configuration = try Self.configuration(WgQuickFixtures.minimal)
        let policy = RoutingPolicy(mode: .selectedApplications(ApplicationSelection([])))

        await #expect(throws: PacketTunnelError.invalidNetworkPlan(.routingModeNotSupported(.selectedApplications))) {
            try await Self.planner(services: []).execute(configuration: configuration, policy: policy)
        }
    }

    @Test
    func reportsServicesThatCannotBeRead() async throws {
        let configuration = try Self.configuration(WgQuickFixtures.minimal)
        let policy = RoutingPolicy(mode: .selectedServices(ServiceSelection([try ServiceIdentifier("telegram")])))
        let planner = PlanTunnelRoutingUseCase(
            serviceCatalog: LoadServiceCatalogUseCase(
                bundled: FixedBundledServiceCatalog(services: []),
                custom: UnavailableCustomServiceRepository()
            )
        )

        await #expect(throws: PacketTunnelError.serviceCatalogUnavailable) {
            try await planner.execute(configuration: configuration, policy: policy)
        }
    }

    private static func planner(services: [ServiceProfile]) -> PlanTunnelRoutingUseCase {
        PlanTunnelRoutingUseCase(
            serviceCatalog: LoadServiceCatalogUseCase(
                bundled: FixedBundledServiceCatalog(services: services),
                custom: InMemoryCustomServiceRepository()
            )
        )
    }

    private static func configuration(_ text: String) throws -> TunnelConfiguration {
        try #require(WgQuickConfigurationParser.parse(text).configuration)
    }
}
