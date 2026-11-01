import ServiceCatalog
import ServiceCatalogTestSupport
import SharedKernel
import Testing

@Suite
struct SaveCustomServiceUseCaseTests {
    @Test
    func savesAServiceWithValidRules() async throws {
        let repository = InMemoryCustomServiceRepository()
        let save = SaveCustomServiceUseCase(repository: repository)

        let service = try await save.execute(
            CustomServiceDraft(
                name: "Work",
                domains: ["corp.example", "mail.corp.example", " "],
                networks: ["10.20.0.0/16"]
            )
        )

        #expect(service.name == "Work")
        #expect(service.rules.domainSuffixes == [try DomainName("corp.example")])
        #expect(service.rules.networks == [try IPNetwork("10.20.0.0/16")])
        #expect(await repository.services == [service])
    }

    @Test
    func rejectsAnInvalidDomain() async {
        let save = SaveCustomServiceUseCase(repository: InMemoryCustomServiceRepository())

        await #expect(throws: CustomServiceError.invalidDomain("not a domain")) {
            try await save.execute(CustomServiceDraft(name: "Work", domains: ["not a domain"], networks: []))
        }
    }

    @Test
    func rejectsAnInvalidNetwork() async {
        let save = SaveCustomServiceUseCase(repository: InMemoryCustomServiceRepository())

        await #expect(throws: CustomServiceError.invalidNetwork("10.0.0.0/33")) {
            try await save.execute(CustomServiceDraft(name: "Work", domains: [], networks: ["10.0.0.0/33"]))
        }
    }

    @Test
    func rejectsAServiceWithoutRules() async {
        let save = SaveCustomServiceUseCase(repository: InMemoryCustomServiceRepository())

        await #expect(throws: CustomServiceError.noRules) {
            try await save.execute(CustomServiceDraft(name: "Work", domains: [" "], networks: []))
        }
    }

    @Test
    func rejectsAnEmptyName() async {
        let save = SaveCustomServiceUseCase(repository: InMemoryCustomServiceRepository())

        await #expect(throws: CustomServiceError.emptyName) {
            try await save.execute(CustomServiceDraft(name: "  ", domains: ["corp.example"], networks: []))
        }
    }

    @Test
    func replacesTheServiceBeingEdited() async throws {
        let repository = InMemoryCustomServiceRepository()
        let save = SaveCustomServiceUseCase(repository: repository)
        let original = try await save.execute(CustomServiceDraft(name: "Work", domains: ["corp.example"], networks: []))

        let edited = try await save.execute(
            CustomServiceDraft(editing: original.id, name: "Office", domains: ["office.example"], networks: [])
        )

        #expect(edited.id == original.id)
        #expect(await repository.services == [edited])
    }
}
