import SwiftUI
import SystemExtension

extension SystemExtensionFailure {
    var title: Text {
        switch self {
        case .appNotInApplicationsFolder: Text("Move Splitway to Applications", bundle: .module)
        case .invalidInstallation: Text("The app is damaged", bundle: .module)
        case .forbiddenBySystemPolicy: Text("Blocked by a policy", bundle: .module)
        case .authorizationRequired: Text("Authorization required", bundle: .module)
        case .cancelled: Text("Installation cancelled", bundle: .module)
        case .unknown: Text("The extension isn’t installed", bundle: .module)
        }
    }

    var message: Text {
        switch self {
        case .appNotInApplicationsFolder:
            Text(
                "System extensions work only for apps in the Applications folder. Move Splitway there and reopen it.",
                bundle: .module
            )
        case .invalidInstallation:
            Text("Download Splitway again and replace the app.", bundle: .module)
        case .forbiddenBySystemPolicy:
            Text("Your organization doesn’t allow this extension. Contact your administrator.", bundle: .module)
        case .authorizationRequired:
            Text("Enter an administrator password when macOS asks, then try again.", bundle: .module)
        case .cancelled:
            Text("Try again and allow the extension in System Settings.", bundle: .module)
        case .unknown:
            Text("Try again. If it keeps failing, restart your Mac.", bundle: .module)
        }
    }
}
