import ApplicationCatalog
import SwiftUI

extension ApplicationRemark {
    var message: Text {
        switch self {
        case .appleApplication:
            Text("Apple app: some of its traffic may bypass the tunnel", bundle: .module)
        case .matchedByPath:
            Text("Not signed by a developer: recognized by its location", bundle: .module)
        }
    }
}
