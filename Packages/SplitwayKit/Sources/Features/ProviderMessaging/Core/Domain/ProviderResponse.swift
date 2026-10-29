import TunnelEngine

public enum ProviderResponse: Sendable, Hashable, Codable {
    case runtimeStatistics(statistics: RuntimeStatistics)
    case routingPolicyApplied
    case health(isTunnelRunning: Bool)
    case failure(reason: ProviderFailure)
}
