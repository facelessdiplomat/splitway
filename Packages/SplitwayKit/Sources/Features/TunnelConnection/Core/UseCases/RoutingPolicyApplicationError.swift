public enum RoutingPolicyApplicationError: Error, Sendable, Equatable {
    case providerUnreachable
    case rejected
}
