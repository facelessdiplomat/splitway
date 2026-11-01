import ServiceCatalog

public actor InMemoryCustomServiceRepository: CustomServiceRepository {
    public private(set) var services: [CustomService]

    public init(services: [CustomService] = []) {
        self.services = services
    }

    public func loadCustomServices() async throws(ServiceCatalogError) -> [CustomService] {
        services
    }

    public func saveCustomServices(_ services: [CustomService]) async throws(ServiceCatalogError) {
        self.services = services
    }
}
