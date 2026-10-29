import SwiftUI

extension TunnelExportProblem {
    var title: Text {
        switch self {
        case .failed: Text("Couldn’t export", bundle: .module)
        case .skippedTunnels: Text("Some tunnels weren’t exported", bundle: .module)
        }
    }

    var message: Text {
        switch self {
        case .failed:
            Text("The tunnel configuration couldn’t be read. Try again.", bundle: .module)
        case .skippedTunnels(let names):
            Self.skippedMessage(names.formatted(.list(type: .and)))
        }
    }

    private static func skippedMessage(_ names: String) -> Text {
        Text("The configuration of \(names) couldn’t be read, so it isn’t in the archive.", bundle: .module)
    }
}
