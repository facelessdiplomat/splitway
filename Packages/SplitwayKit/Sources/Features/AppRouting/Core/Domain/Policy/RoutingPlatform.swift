public enum RoutingPlatform: Sendable, Hashable {
    case macOS
    case iOS

    public var supportedModes: Set<RoutingModeKind> {
        switch self {
        case .macOS: [.allTraffic, .selectedApplications]
        case .iOS: [.allTraffic, .selectedServices]
        }
    }
}
