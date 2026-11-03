import AppRouting
import SwiftUI

extension RoutingModeKind {
    public var title: Text {
        switch self {
        case .allTraffic: Text("All traffic", bundle: .module)
        case .selectedApplications: Text("Selected apps", bundle: .module)
        }
    }
}
