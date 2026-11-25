import ServiceCatalog

public struct FixedBundledServiceCatalog: BundledServiceCatalog {
    private let services: [ServiceProfile]

    public init(services: [ServiceProfile]) {
        self.services = services
    }

    public func loadServices() throws(ServiceCatalogError) -> [ServiceProfile] {
        services
    }
}
