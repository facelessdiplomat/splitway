import AppRouting
import SwiftUI

extension RoutingPolicyWarning {
    var message: Text {
        switch self {
        case .emptyApplicationSelection:
            Text("Choose at least one app, or no traffic will use the tunnel.", bundle: .module)
        case .emptyServiceSelection:
            Text("Choose at least one service, or no traffic will use the tunnel.", bundle: .module)
        }
    }
}
