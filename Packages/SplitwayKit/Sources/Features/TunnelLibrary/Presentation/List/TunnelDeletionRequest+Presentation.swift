import SwiftUI

extension TunnelDeletionRequest {
    var title: Text {
        Text("Delete “\(tunnelName)”?", bundle: .module)
    }

    var consequences: Text {
        if disconnectsTunnel {
            Text(
                "The connected tunnel will be disconnected, and its configuration and keys removed from this device.",
                bundle: .module
            )
        } else {
            Text("The tunnel configuration and keys will be removed from this device.", bundle: .module)
        }
    }
}
