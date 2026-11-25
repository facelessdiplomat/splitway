import SwiftUI
import TunnelImport

extension ImportSource {
    var title: Text {
        switch self {
        case .text: Text("Clipboard", bundle: .module)
        case .qrCode: Text("QR code", bundle: .module)
        case .file(let name): Text(verbatim: name)
        case .archiveEntry(let archiveName, let fileName): Text(verbatim: "\(archiveName) › \(fileName)")
        }
    }
}
