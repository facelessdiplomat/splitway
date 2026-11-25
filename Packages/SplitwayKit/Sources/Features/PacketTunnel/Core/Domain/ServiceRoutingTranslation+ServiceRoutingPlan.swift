import ServiceCatalog
import TunnelEngine

extension ServiceRoutingTranslation {
    init(_ plan: ServiceRoutingPlan) {
        self.init(
            virtualResolver: plan.virtualResolver,
            upstreamResolver: plan.upstreamResolver,
            fakeIPv4Network: plan.fakeIPv4Network,
            fakeIPv6Network: plan.fakeIPv6Network
        )
    }
}
