import Foundation
import ServiceCatalog
import ServiceCatalogInfrastructure
import ServiceCatalogTestSupport
import Testing

@Suite
struct FileCustomServiceRepositoryTests {
    @Test
    func returnsNoServicesBeforeTheFirstSave() async throws {
        let repository = FileCustomServiceRepository(directory: Self.temporaryDirectory())

        let services = try await repository.loadCustomServices()

        #expect(services.isEmpty)
    }

    @Test
    func keepsSavedServicesForTheNextReader() async throws {
        let directory = Self.temporaryDirectory()
        let work = try await ServiceCatalogFixtures.customService(name: "Work", domains: ["corp.example"])
        try await FileCustomServiceRepository(directory: directory).saveCustomServices([work])

        let services = try await FileCustomServiceRepository(directory: directory).loadCustomServices()

        #expect(services == [work])
    }

    @Test
    func reportsADocumentItCannotRead() async throws {
        let directory = Self.temporaryDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: directory.appending(path: "custom-services.json"))

        await #expect(throws: ServiceCatalogError.customServicesUnavailable) {
            try await FileCustomServiceRepository(directory: directory).loadCustomServices()
        }
    }

    private static func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    }
}
