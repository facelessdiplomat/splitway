import AppRouting
import ServiceCatalog
import SharedKernel

public enum ServiceCatalogFixtures {
    public static func profile(
        id: String,
        name: String,
        category: ServiceCategory = .messaging,
        domains: [String] = ["example.org"],
        networks: [String] = []
    ) throws -> ServiceProfile {
        try ServiceProfile(
            id: ServiceIdentifier(id),
            displayName: name,
            category: category,
            icon: ServiceIcon(monogram: String(name.prefix(1)), tint: ServiceTint(hexadecimal: "#229ED9")),
            rules: ServiceRules(
                domainSuffixes: domains.map { text in try DomainName(text) },
                networks: networks.map { text in try IPNetwork(text) }
            ),
            notes: "Fixture"
        )
    }

    public static func customService(name: String, domains: [String] = ["corp.example"]) async throws -> CustomService {
        try await SaveCustomServiceUseCase(repository: InMemoryCustomServiceRepository())
            .execute(CustomServiceDraft(name: name, domains: domains, networks: []))
    }
}
