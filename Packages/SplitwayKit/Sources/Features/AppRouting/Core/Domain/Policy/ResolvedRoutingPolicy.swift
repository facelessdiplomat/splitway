public struct ResolvedRoutingPolicy: Sendable, Hashable {
    public let policy: RoutingPolicy
    public let unsupportedMode: RoutingModeKind?

    public init(policy: RoutingPolicy, unsupportedMode: RoutingModeKind?) {
        self.policy = policy
        self.unsupportedMode = unsupportedMode
    }
}
