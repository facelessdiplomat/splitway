import SwiftUI
import TunnelImport

extension ImportSourceFailureReason {
    var message: Text {
        switch self {
        case .unreadable:
            Text("The file couldn’t be read.", bundle: .module)
        case .notText:
            Text("This file isn’t a WireGuard configuration or a ZIP archive.", bundle: .module)
        case .archiveRejected(.unreadableArchive):
            Text("The archive couldn’t be opened.", bundle: .module)
        case .archiveRejected(.tooManyConfigurationFiles(let limit)):
            Text("The archive has more than \(limit) configurations.", bundle: .module)
        case .archiveRejected(.configurationsTooLarge):
            Text("The configurations in the archive are too large.", bundle: .module)
        case .noConfigurationsInArchive:
            Text("The archive has no configurations.", bundle: .module)
        }
    }
}
