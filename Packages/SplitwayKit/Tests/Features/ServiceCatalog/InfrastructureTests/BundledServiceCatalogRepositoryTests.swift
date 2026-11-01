import AppRouting
import ServiceCatalog
import ServiceCatalogInfrastructure
import SharedKernel
import Testing

@Suite
struct BundledServiceCatalogRepositoryTests {
    @Test
    func readsEveryFieldOfAServiceEntry() throws {
        let file = try CatalogFixtureFile(contents: CatalogFixtureFile.document(services: CatalogFixtureFile.entry()))

        let services = try BundledServiceCatalogRepository(catalogURL: file.url).loadServices()

        let telegram = try #require(services.first)
        #expect(telegram.id == (try ServiceIdentifier("telegram")))
        #expect(telegram.displayName == "Telegram")
        #expect(telegram.category == .messaging)
        #expect(telegram.icon.monogram == "T")
        #expect(telegram.rules.domainSuffixes.map(\.description) == ["t.me", "telegram.org"])
        #expect(telegram.rules.networks == [try IPNetwork("91.108.4.0/22"), try IPNetwork("2001:b28:f23d::/48")])
        #expect(telegram.notes == "https://core.telegram.org/resources/cidr.txt")
    }

    @Test
    func rejectsAnUnknownSchemaVersion() throws {
        let file = try CatalogFixtureFile(
            contents: CatalogFixtureFile.document(schemaVersion: 2, services: CatalogFixtureFile.entry())
        )

        #expect(throws: ServiceCatalogError.bundledCatalogUnreadable) {
            try BundledServiceCatalogRepository(catalogURL: file.url).loadServices()
        }
    }

    @Test
    func namesTheEntryWithAMalformedDomain() throws {
        let file = try CatalogFixtureFile(
            contents: CatalogFixtureFile.document(
                services: CatalogFixtureFile.entry(id: "broken", domains: #"["not a domain"]"#)
            )
        )

        #expect(throws: ServiceCatalogError.invalidCatalogEntry("broken")) {
            try BundledServiceCatalogRepository(catalogURL: file.url).loadServices()
        }
    }

    @Test
    func rejectsAMissingCatalog() {
        #expect(throws: ServiceCatalogError.bundledCatalogUnreadable) {
            try BundledServiceCatalogRepository(catalogURL: nil).loadServices()
        }
    }
}
