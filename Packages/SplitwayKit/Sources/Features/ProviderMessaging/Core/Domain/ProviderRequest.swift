import AppRouting

public enum ProviderRequest: Sendable, Hashable, Codable {
    case runtimeStatistics
    case applyRoutingPolicy(policy: RoutingPolicy)
    case healthCheck
}
