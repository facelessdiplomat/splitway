public enum ConfigurationIssueKind: Equatable, Sendable {
    case configurationTooLarge
    case malformedLine
    case keyOutsideSection(String)
    case unknownSection(String)
    case missingInterfaceSection
    case multipleInterfaceSections
    case unknownKey(String)
    case keyNotAllowedInSection(WgQuickKey)
    case duplicateKey(WgQuickKey)
    case invalidValue(WgQuickKey, ConfigurationValueError)
    case missingPrivateKey
    case missingPeerPublicKey
    case duplicatePeerPublicKey(PublicKey)
    case amneziaWGNotSupported(String)
    case unsupportedWgQuickKey(String)
    case configurationWarning(TunnelConfigurationWarning)

    public var severity: ConfigurationIssueSeverity {
        switch self {
        case .unsupportedWgQuickKey, .configurationWarning: .warning
        default: .error
        }
    }
}
