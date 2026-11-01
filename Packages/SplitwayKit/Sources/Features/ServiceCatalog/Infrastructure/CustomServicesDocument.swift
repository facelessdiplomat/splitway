struct CustomServicesDocument: Codable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let services: [CustomServiceEntry]
}
