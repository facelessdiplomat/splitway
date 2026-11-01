public enum ServiceCatalogError: Error, Sendable, Equatable {
    case bundledCatalogUnreadable
    case invalidCatalogEntry(String)
    case customServicesUnavailable
}
