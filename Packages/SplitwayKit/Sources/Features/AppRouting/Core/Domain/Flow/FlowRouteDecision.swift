public enum FlowRouteDecision: Sendable, Hashable {
    case tunnel
    case direct
    case block
}
