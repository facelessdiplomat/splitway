import ServiceCatalog

public struct UnavailableCustomServiceRepository: CustomServiceRepository {
    public init() {}

    public func loadCustomServices() async throws(ServiceCatalogError) -> [CustomService] {
        throw .customServicesUnavailable
    }

    public func saveCustomServices(_ services: [CustomService]) async throws(ServiceCatalogError) {
        throw .customServicesUnavailable
    }
}
