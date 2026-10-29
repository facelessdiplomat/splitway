import SwiftUI
import TunnelConfigurationPresentation
import TunnelEditor
import TunnelLibrary

extension TunnelDraftProblemReason {
    var message: Text {
        switch self {
        case .missing: Text("Required", bundle: .module)
        case .invalidName(.empty): Text("Enter a name.", bundle: .module)
        case .invalidName(.tooLong): Text("Use at most \(TunnelName.maximumLength) characters.", bundle: .module)
        case .invalidName(.containsControlCharacters): Text("Remove control characters.", bundle: .module)
        case .invalidValue(let error): Text(error.message)
        case .duplicatePeerPublicKey: Text("Another peer already uses this key.", bundle: .module)
        }
    }
}
