import Diagnostics
import SwiftUI

extension LogSource {
    var title: Text {
        switch self {
        case .application: Text("App", bundle: .module)
        case .tunnelExtension: Text("Tunnel", bundle: .module)
        case .engine: Text(verbatim: "WireGuard")
        }
    }
}
