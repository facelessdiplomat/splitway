struct ServiceCatalogDocument: Decodable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let services: [ServiceCatalogEntry]
}
