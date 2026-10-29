public enum SystemExtensionFailure: Error, Sendable, Hashable {
    case appNotInApplicationsFolder
    case invalidInstallation
    case forbiddenBySystemPolicy
    case authorizationRequired
    case cancelled
    case unknown
}
