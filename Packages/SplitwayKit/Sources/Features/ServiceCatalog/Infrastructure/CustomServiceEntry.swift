import AppRouting
import ServiceCatalog
import SharedKernel

struct CustomServiceEntry: Codable {
    let id: ServiceIdentifier
    let name: String
    let domainSuffixes: [String]
    let networks: [String]

    init(_ service: CustomService) {
        id = service.id
        name = service.name
        domainSuffixes = service.rules.domainSuffixes.map(\.description)
        networks = service.rules.networks.map(\.description)
    }

    func service() throws -> CustomService {
        try CustomService(
            id: id,
            name: name,
            rules: ServiceRules(
                domainSuffixes: domainSuffixes.map { text in try DomainName(text) },
                networks: networks.map { text in try IPNetwork(text) }
            )
        )
    }
}
