import Foundation
import TunnelConfiguration

extension ConfigurationIssueKind {
    public var message: LocalizedStringResource {
        documentMessage ?? keyMessage ?? contentMessage
    }

    private var documentMessage: LocalizedStringResource? {
        switch self {
        case .configurationTooLarge: .moduleResource("The configuration is too large.")
        case .malformedLine: .moduleResource("This line is not a section, a key with a value or a comment.")
        case .keyOutsideSection(let key): .moduleResource("\(key) is outside any section.")
        case .unknownSection(let section): .moduleResource("Unknown section [\(section)].")
        case .missingInterfaceSection: .moduleResource("The [Interface] section is missing.")
        case .multipleInterfaceSections: .moduleResource("There is more than one [Interface] section.")
        default: nil
        }
    }

    private var keyMessage: LocalizedStringResource? {
        switch self {
        case .unknownKey(let key): .moduleResource("Unknown key \(key).")
        case .keyNotAllowedInSection(let key): .moduleResource("\(key.name) is not allowed in this section.")
        case .duplicateKey(let key): .moduleResource("\(key.name) appears more than once.")
        case .invalidValue(let key, _): .moduleResource("The value of \(key.name) is invalid.")
        case .amneziaWGNotSupported(let key):
            .moduleResource("\(key) belongs to AmneziaWG, which is not supported yet.")
        case .unsupportedWgQuickKey(let key): .moduleResource("\(key) is a wg-quick setting and will be ignored.")
        default: nil
        }
    }

    private var contentMessage: LocalizedStringResource {
        switch self {
        case .missingPrivateKey: .moduleResource("The private key is missing.")
        case .missingPeerPublicKey: .moduleResource("A peer has no public key.")
        case .duplicatePeerPublicKey: .moduleResource("Two peers have the same public key.")
        case .configurationWarning(let warning): warning.message
        default: .moduleResource("The configuration is invalid.")
        }
    }
}
