public struct RoutingPolicy: Sendable, Hashable {
    public static let `default` = RoutingPolicy(mode: .allTraffic)

    public let applicationSelection: ApplicationSelection
    public let serviceSelection: ServiceSelection
    public let whenTunnelUnavailable: TunnelUnavailableBehavior
    private let modeKind: RoutingModeKind

    public init(mode: RoutingMode, whenTunnelUnavailable: TunnelUnavailableBehavior = .block) {
        self.init(
            modeKind: mode.kind,
            applicationSelection: mode.applicationSelection,
            serviceSelection: mode.serviceSelection,
            whenTunnelUnavailable: whenTunnelUnavailable
        )
    }

    init(
        modeKind: RoutingModeKind,
        applicationSelection: ApplicationSelection,
        serviceSelection: ServiceSelection,
        whenTunnelUnavailable: TunnelUnavailableBehavior
    ) {
        self.modeKind = modeKind
        self.applicationSelection = applicationSelection
        self.serviceSelection = serviceSelection
        self.whenTunnelUnavailable = whenTunnelUnavailable
    }

    public var mode: RoutingMode {
        switch modeKind {
        case .allTraffic: .allTraffic
        case .selectedApplications: .selectedApplications(applicationSelection)
        case .selectedServices: .selectedServices(serviceSelection)
        }
    }
}
