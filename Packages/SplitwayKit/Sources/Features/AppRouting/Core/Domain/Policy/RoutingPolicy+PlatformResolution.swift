extension RoutingPolicy {
    public func resolved(on platform: RoutingPlatform) -> ResolvedRoutingPolicy {
        guard !platform.supportedModes.contains(mode.kind) else {
            return ResolvedRoutingPolicy(policy: self, unsupportedMode: nil)
        }
        return ResolvedRoutingPolicy(
            policy: RoutingPolicy(mode: .allTraffic, whenTunnelUnavailable: whenTunnelUnavailable),
            unsupportedMode: mode.kind
        )
    }
}
