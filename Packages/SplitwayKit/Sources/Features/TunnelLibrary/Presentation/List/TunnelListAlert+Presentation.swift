import SwiftUI

extension TunnelListAlert {
    var title: Text {
        switch self {
        case .library: Text("Couldn’t update tunnels", bundle: .module)
        case .connection: Text("Couldn’t connect", bundle: .module)
        }
    }

    var message: Text {
        switch self {
        case .library(let error):
            error.message
        case .connection:
            Text("Try again in a moment. If it keeps failing, check the tunnel configuration.", bundle: .module)
        }
    }
}
