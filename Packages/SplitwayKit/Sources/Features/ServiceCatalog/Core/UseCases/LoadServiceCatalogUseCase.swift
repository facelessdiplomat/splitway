public struct LoadServiceCatalogUseCase: Sendable {
    private let bundled: any BundledServiceCatalog
    private let custom: any CustomServiceRepository

    public init(bundled: any BundledServiceCatalog, custom: any CustomServiceRepository) {
        self.bundled = bundled
        self.custom = custom
    }

    public func execute() async throws(ServiceCatalogError) -> ServiceCatalog {
        let bundledServices = try bundled.loadServices()
        let customServices = try await custom.loadCustomServices()
        return ServiceCatalog(services: bundledServices + customServices.map(\.profile))
    }
}
