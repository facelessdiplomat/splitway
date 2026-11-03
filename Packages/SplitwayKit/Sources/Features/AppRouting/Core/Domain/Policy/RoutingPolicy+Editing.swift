extension RoutingPolicy {
    public func switchingMode(to kind: RoutingModeKind) -> RoutingPolicy {
        RoutingPolicy(
            modeKind: kind,
            applicationSelection: applicationSelection,
            whenTunnelUnavailable: whenTunnelUnavailable
        )
    }

    public func replacingApplicationSelection(with selection: ApplicationSelection) -> RoutingPolicy {
        RoutingPolicy(
            modeKind: mode.kind,
            applicationSelection: selection,
            whenTunnelUnavailable: whenTunnelUnavailable
        )
    }

    public func replacingTunnelUnavailableBehavior(with behavior: TunnelUnavailableBehavior) -> RoutingPolicy {
        RoutingPolicy(
            modeKind: mode.kind,
            applicationSelection: applicationSelection,
            whenTunnelUnavailable: behavior
        )
    }
}
