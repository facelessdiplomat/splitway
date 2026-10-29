import SwiftUI

extension SystemExtensionWizardStep {
    var title: Text {
        switch self {
        case .introduction: Text("Install the network extension", bundle: .module)
        case .installing: Text("Installing the extension…", bundle: .module)
        case .awaitingApproval: Text("Allow the extension", bundle: .module)
        case .ready: Text("The extension is ready", bundle: .module)
        case .restartRequired: Text("Restart your Mac", bundle: .module)
        case .failed(let failure): failure.title
        }
    }

    var message: Text {
        switch self {
        case .introduction:
            Text("Splitway runs the tunnel in a system extension. macOS asks you to allow it once.", bundle: .module)
        case .installing:
            Text("This takes a few seconds.", bundle: .module)
        case .awaitingApproval:
            Text(
                "In System Settings › General › Login Items & Extensions, turn on Splitway under Network Extensions.",
                bundle: .module
            )
        case .ready:
            Text("You can connect your tunnels.", bundle: .module)
        case .restartRequired:
            Text("macOS finishes installing the extension after a restart.", bundle: .module)
        case .failed(let failure):
            failure.message
        }
    }

    var symbolName: String {
        switch self {
        case .introduction, .installing: "puzzlepiece.extension"
        case .awaitingApproval: "switch.2"
        case .ready: "checkmark.circle"
        case .restartRequired: "restart.circle"
        case .failed: "exclamationmark.triangle"
        }
    }
}
