public protocol BundledServiceCatalog: Sendable {
    func loadServices() throws(ServiceCatalogError) -> [ServiceProfile]
}
