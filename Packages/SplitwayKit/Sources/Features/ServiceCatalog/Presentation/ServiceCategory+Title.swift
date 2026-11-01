import ServiceCatalog
import SwiftUI

extension ServiceCategory {
    var title: Text {
        switch self {
        case .messaging: Text("Messaging", bundle: .module)
        case .social: Text("Social", bundle: .module)
        case .video: Text("Video", bundle: .module)
        case .music: Text("Music", bundle: .module)
        case .ai: Text("AI Assistants", bundle: .module)
        case .development: Text("Development", bundle: .module)
        case .custom: Text("Your Services", bundle: .module)
        }
    }
}
