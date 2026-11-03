public struct RoutingPolicy: Sendable, Hashable {
    public static let `default` = RoutingPolicy(mode: .allTraffic)

    public let applicationSelection: ApplicationSelection
    public let whenTunnelUnavailable: TunnelUnavailableBehavior
    private let modeKind: RoutingModeKind

    public init(mode: RoutingMode, whenTunnelUnavailable: TunnelUnavailableBehavior = .block) {
        self.init(
            modeKind: mode.kind,
            applicationSelection: mode.applicationSelection,
            whenTunnelUnavailable: whenTunnelUnavailable
        )
    }

    init(
        modeKind: RoutingModeKind,
        applicationSelection: ApplicationSelection,
        whenTunnelUnavailable: TunnelUnavailableBehavior
    ) {
        self.modeKind = modeKind
        self.applicationSelection = applicationSelection
        self.whenTunnelUnavailable = whenTunnelUnavailable
    }

    public var mode: RoutingMode {
        switch modeKind {
        case .allTraffic: .allTraffic
        case .selectedApplications: .selectedApplications(applicationSelection)
        }
    }
}
