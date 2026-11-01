import AppRouting
import ServiceCatalog
import TunnelConfiguration
import TunnelEngine

public struct PlanTunnelRoutingUseCase: Sendable {
    private let serviceCatalog: LoadServiceCatalogUseCase
    private let compiler: ServiceRoutingPlanCompiler

    public init(
        serviceCatalog: LoadServiceCatalogUseCase,
        compiler: ServiceRoutingPlanCompiler = ServiceRoutingPlanCompiler()
    ) {
        self.serviceCatalog = serviceCatalog
        self.compiler = compiler
    }

    public func execute(
        configuration: TunnelConfiguration,
        policy: RoutingPolicy
    ) async throws(PacketTunnelError) -> TunnelRouting {
        guard case .selectedServices(let selection) = policy.mode else {
            return TunnelRouting(
                mode: policy.mode.kind,
                networkPlan: try fullTunnelPlan(for: configuration, routedBy: policy),
                translation: nil
            )
        }
        let catalog = try await loadedCatalog()
        let servicePlan = compiler.compile(selection: selection, catalog: catalog, configuration: configuration)
        do {
            return TunnelRouting(
                mode: .selectedServices,
                networkPlan: try SelectedServicesNetworkPlanner.plan(for: servicePlan, configuration: configuration),
                translation: ServiceRoutingTranslation(servicePlan)
            )
        } catch {
            throw .invalidNetworkPlan(error)
        }
    }

    private func fullTunnelPlan(
        for configuration: TunnelConfiguration,
        routedBy policy: RoutingPolicy
    ) throws(PacketTunnelError) -> TunnelNetworkPlan {
        do {
            return try TunnelNetworkPlanner.plan(for: configuration, routedBy: policy)
        } catch {
            throw .invalidNetworkPlan(error)
        }
    }

    private func loadedCatalog() async throws(PacketTunnelError) -> ServiceCatalog {
        do {
            return try await serviceCatalog.execute()
        } catch {
            throw .serviceCatalogUnavailable
        }
    }
}
