import SwiftUI

extension OnboardingPage {
    var title: Text {
        switch self {
        case .welcome: Text("Welcome to Splitway", bundle: .module)
        case .privacy: Text("Your data stays with you", bundle: .module)
        case .systemPermissions, .systemExtension: Text("What the system will ask", bundle: .module)
        }
    }

    var message: Text {
        switch self {
        case .welcome: welcomeMessage
        case .privacy:
            Text(
                "No accounts, analytics or ads. Tunnels, keys and the log stay on this device until you share them.",
                bundle: .module
            )
        case .systemPermissions, .systemExtension: permissionsMessage
        }
    }

    var symbolName: String {
        switch self {
        case .welcome: "point.3.connected.trianglepath.dotted"
        case .privacy: "hand.raised"
        case .systemPermissions, .systemExtension: "checkmark.shield"
        }
    }

    private var welcomeMessage: Text {
        Text(
            "Import your WireGuard tunnel and choose which apps use it. Everything else stays direct.",
            bundle: .module)
    }

    private var permissionsMessage: Text {
        Text(
            "macOS asks once to allow the Splitway network extension and to add a VPN configuration.",
            bundle: .module
        )
    }
}
