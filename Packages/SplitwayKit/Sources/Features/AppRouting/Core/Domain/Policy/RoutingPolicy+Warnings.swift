extension RoutingPolicy {
    public var warnings: [RoutingPolicyWarning] {
        switch mode {
        case .allTraffic:
            []
        case .selectedApplications(let selection):
            selection.isEmpty ? [.emptyApplicationSelection] : []
        }
    }
}
