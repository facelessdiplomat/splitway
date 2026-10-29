public enum RoutingMode: Sendable, Hashable {
    case allTraffic
    case selectedApplications(ApplicationSelection)
    case selectedServices(ServiceSelection)

    public var kind: RoutingModeKind {
        switch self {
        case .allTraffic: .allTraffic
        case .selectedApplications: .selectedApplications
        case .selectedServices: .selectedServices
        }
    }
}
