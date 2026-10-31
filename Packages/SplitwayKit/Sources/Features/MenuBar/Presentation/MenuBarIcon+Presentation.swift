import SwiftUI

extension MenuBarIcon {
    var symbolName: String {
        switch self {
        case .disconnected: "shield"
        case .connecting: "shield.lefthalf.filled"
        case .connected: "checkmark.shield.fill"
        case .failed: "exclamationmark.shield.fill"
        }
    }

    var accessibilityLabel: Text {
        switch self {
        case .disconnected: Text("Splitway, disconnected", bundle: .module)
        case .connecting: Text("Splitway, connecting", bundle: .module)
        case .connected: Text("Splitway, connected", bundle: .module)
        case .failed: Text("Splitway, connection failed", bundle: .module)
        }
    }
}
