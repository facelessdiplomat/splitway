public protocol CustomServiceRepository: Sendable {
    func loadCustomServices() async throws(ServiceCatalogError) -> [CustomService]
    func saveCustomServices(_ services: [CustomService]) async throws(ServiceCatalogError)
}
