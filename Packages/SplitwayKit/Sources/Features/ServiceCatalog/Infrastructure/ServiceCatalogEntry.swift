struct ServiceCatalogEntry: Decodable {
    let id: String
    let displayName: String
    let category: String
    let monogram: String
    let tint: String
    let domainSuffixes: [String]
    let ipv4Networks: [String]
    let ipv6Networks: [String]
    let notes: String
}
