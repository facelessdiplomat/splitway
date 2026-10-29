import SwiftUI
import TunnelConnectionPresentation
import TunnelLibrary

extension TunnelListAlert {
    var title: Text {
        switch self {
        case .library: Text("Couldn’t update tunnels", bundle: .module)
        case .connection(let failure, _): Text(failure.explanation.title)
        }
    }

    var message: Text {
        switch self {
        case .library(let error): error.message
        case .connection(let failure, _): Text(failure.explanation.message)
        }
    }

    var suggestedAction: ConnectionFailureAction {
        if case .connection(let failure, _) = self { failure.explanation.suggestedAction } else { .none }
    }

    var tunnelID: TunnelIdentifier? {
        if case .connection(_, let tunnelID) = self { tunnelID } else { nil }
    }
}
