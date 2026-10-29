public enum RoutingModeKind: String, Sendable, Hashable, CaseIterable, Codable {
    case allTraffic
    case selectedApplications
    case selectedServices
}
