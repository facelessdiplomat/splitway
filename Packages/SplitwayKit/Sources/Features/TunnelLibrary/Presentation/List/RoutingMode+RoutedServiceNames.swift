import AppRouting
import Foundation

extension RoutingMode {
    func routedServiceNames(naming serviceNames: [ServiceIdentifier: String]) -> [String] {
        guard case .selectedServices(let selection) = self else { return [] }
        return selection.services.compactMap { service in serviceNames[service] }.sorted { first, second in
            first.localizedStandardCompare(second) == .orderedAscending
        }
    }
}
