import Foundation
import ServiceCatalog

public struct BundledServiceCatalogRepository: BundledServiceCatalog {
    public static var bundled: BundledServiceCatalogRepository {
        BundledServiceCatalogRepository(catalogURL: Bundle.module.url(forResource: "catalog", withExtension: "json"))
    }

    private let catalogURL: URL?

    public init(catalogURL: URL?) {
        self.catalogURL = catalogURL
    }

    public func loadServices() throws(ServiceCatalogError) -> [ServiceProfile] {
        guard let catalogURL, let data = try? Data(contentsOf: catalogURL),
            let document = try? JSONDecoder().decode(ServiceCatalogDocument.self, from: data),
            document.schemaVersion == ServiceCatalogDocument.currentSchemaVersion
        else { throw .bundledCatalogUnreadable }
        return try document.services.map { entry throws(ServiceCatalogError) in try entry.profile() }
    }
}
