public enum RoutingMode: Sendable, Hashable {
    case allTraffic
    case selectedApplications(ApplicationSelection)

    public var kind: RoutingModeKind {
        switch self {
        case .allTraffic: .allTraffic
        case .selectedApplications: .selectedApplications
        }
    }

    var applicationSelection: ApplicationSelection {
        guard case .selectedApplications(let selection) = self else { return ApplicationSelection([]) }
        return selection
    }
}
