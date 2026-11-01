public enum CustomServiceError: Error, Sendable, Equatable {
    case emptyName
    case invalidDomain(String)
    case invalidNetwork(String)
    case noRules
    case storageUnavailable
}
