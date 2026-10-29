import TunnelConfigurationPresentation
import UniformTypeIdentifiers

extension ExportedDocumentKind {
    var contentType: UTType {
        switch self {
        case .configuration: .wireGuardConfiguration
        case .archive: .zip
        }
    }
}
