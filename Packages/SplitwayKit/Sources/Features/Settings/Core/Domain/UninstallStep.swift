public enum UninstallStep: Int, Sendable, CaseIterable, Comparable {
    case stopTunnel
    case removeVPNConfigurations
    case removeSecrets
    case removeLoginItem
    case removeAppData
    case deactivateSystemExtension

    public static func < (lhs: UninstallStep, rhs: UninstallStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
