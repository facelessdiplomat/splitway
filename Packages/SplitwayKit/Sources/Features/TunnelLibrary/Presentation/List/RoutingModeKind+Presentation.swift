import AppRouting
import SwiftUI

extension RoutingModeKind {
    var title: Text {
        switch self {
        case .allTraffic: Text("All traffic", bundle: .module)
        case .selectedApplications: Text("Selected apps", bundle: .module)
        case .selectedServices: Text("Selected services", bundle: .module)
        }
    }
}
