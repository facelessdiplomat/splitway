import SwiftUI

extension TunnelImportAlert {
    var title: Text {
        switch self {
        case .emptyClipboard: Text("Nothing to paste", bundle: .module)
        case .library: Text("Couldn’t import", bundle: .module)
        }
    }

    var message: Text {
        switch self {
        case .emptyClipboard: Text("Copy a WireGuard configuration and try again.", bundle: .module)
        case .library: Text("The tunnel storage couldn’t be read or written. Try again.", bundle: .module)
        }
    }
}
