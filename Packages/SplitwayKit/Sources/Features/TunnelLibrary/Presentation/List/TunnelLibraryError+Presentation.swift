import SwiftUI
import TunnelLibrary

extension TunnelLibraryError {
    var message: Text {
        switch self {
        case .storage: Text("The tunnel storage couldn’t be read or written.", bundle: .module)
        case .tunnelNotFound: Text("This tunnel no longer exists.", bundle: .module)
        case .unreadableConfiguration: Text("The tunnel configuration can’t be read.", bundle: .module)
        case .activeTunnelCouldNotBeStopped: Text("The connected tunnel couldn’t be disconnected.", bundle: .module)
        case .orderDoesNotMatchTunnels: Text("The tunnel list has changed. Try again.", bundle: .module)
        case .archiveFailed: Text("The archive couldn’t be created.", bundle: .module)
        }
    }
}
