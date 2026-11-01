import AppRouting
import ServiceCatalog
import ServiceCatalogTestSupport
import Testing

@Suite
struct LoadServiceCatalogUseCaseTests {
    @Test
    func listsBundledServicesBeforeCustomOnes() async throws {
        let telegram = try ServiceCatalogFixtures.profile(id: "telegram", name: "Telegram")
        let work = try await ServiceCatalogFixtures.customService(name: "Work")
        let load = LoadServiceCatalogUseCase(
            bundled: FixedBundledServiceCatalog(services: [telegram]),
            custom: InMemoryCustomServiceRepository(services: [work])
        )

        let catalog = try await load.execute()

        #expect(catalog.services.map(\.id) == [telegram.id, work.id])
        #expect(catalog.service(work.id)?.category == .custom)
    }

    @Test
    func findsTheSelectedServicesInTheOrderOfTheCatalog() async throws {
        let telegram = try ServiceCatalogFixtures.profile(id: "telegram", name: "Telegram")
        let youtube = try ServiceCatalogFixtures.profile(id: "youtube", name: "YouTube", domains: ["youtube.com"])
        let load = LoadServiceCatalogUseCase(
            bundled: FixedBundledServiceCatalog(services: [telegram, youtube]),
            custom: InMemoryCustomServiceRepository()
        )
        let catalog = try await load.execute()

        let selected = catalog.services(in: ServiceSelection([youtube.id, try ServiceIdentifier("unknown"), telegram.id]))

        #expect(selected == [telegram, youtube])
    }
}
