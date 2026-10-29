import SwiftUI

extension TunnelRowStatus {
    var title: Text {
        switch self {
        case .disconnected: Text("Disconnected", bundle: .module)
        case .connecting: Text("Connecting…", bundle: .module)
        case .connected: Text("Connected", bundle: .module)
        case .reconnecting: Text("Reconnecting…", bundle: .module)
        case .disconnecting: Text("Disconnecting…", bundle: .module)
        case .failed: Text("Connection failed", bundle: .module)
        case .unavailable: Text("Configuration unavailable", bundle: .module)
        }
    }
}
