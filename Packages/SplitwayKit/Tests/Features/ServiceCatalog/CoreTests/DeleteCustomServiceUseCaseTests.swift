import AppRouting
import ServiceCatalog
import ServiceCatalogTestSupport
import Testing

@Suite
struct DeleteCustomServiceUseCaseTests {
    @Test
    func removesTheServiceAndKeepsTheOthers() async throws {
        let work = try await ServiceCatalogFixtures.customService(name: "Work")
        let home = try await ServiceCatalogFixtures.customService(name: "Home", domains: ["home.example"])
        let repository = InMemoryCustomServiceRepository(services: [work, home])

        try await DeleteCustomServiceUseCase(repository: repository).execute(work.id)

        #expect(await repository.services == [home])
    }

    @Test
    func reportsAStorageThatCannotBeChanged() async throws {
        let identifier = try ServiceIdentifier("custom-work")
        let delete = DeleteCustomServiceUseCase(repository: UnavailableCustomServiceRepository())

        await #expect(throws: CustomServiceError.storageUnavailable) {
            try await delete.execute(identifier)
        }
    }
}
