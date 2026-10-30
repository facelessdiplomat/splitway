import AppRouting
import Foundation

extension RoutingMode {
    var routedApplicationNames: [String] {
        guard case .selectedApplications(let selection) = self else { return [] }
        return selection.applications.map(\.displayName).sorted { first, second in
            first.localizedStandardCompare(second) == .orderedAscending
        }
    }
}
