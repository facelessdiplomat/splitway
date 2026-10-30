import ApplicationCatalog
import SwiftUI

extension ApplicationCatalogFilter {
    var title: Text {
        switch self {
        case .all: Text("All", bundle: .module)
        case .selected: Text("Selected", bundle: .module)
        case .commandLineTools: Text("Command-Line Tools", bundle: .module)
        }
    }
}
