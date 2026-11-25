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

    var applicationSelection: ApplicationSelection {
        guard case .selectedApplications(let selection) = self else { return ApplicationSelection([]) }
        return selection
    }

    var serviceSelection: ServiceSelection {
        guard case .selectedServices(let selection) = self else { return ServiceSelection([]) }
        return selection
    }
}
