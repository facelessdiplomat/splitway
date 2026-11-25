import ServiceCatalog
import ServiceCatalogTestSupport
import Testing

@Suite
struct CustomServiceDraftTests {
    @Test
    func listsEveryProblemOfTheDraft() {
        let draft = CustomServiceDraft(
            name: " ",
            domains: ["corp.example", "not a domain"],
            networks: ["10.0.0.0/33", ""]
        )

        #expect(draft.problems == [.emptyName, .invalidDomain("not a domain"), .invalidNetwork("10.0.0.0/33")])
    }

    @Test
    func needsAtLeastOneRule() {
        let draft = CustomServiceDraft(name: "Work", domains: [" "], networks: [])

        #expect(draft.problems == [.noRules])
    }

    @Test
    func hasNoProblemsWhenEveryEntryIsValid() {
        let draft = CustomServiceDraft(name: "Work", domains: ["corp.example"], networks: ["10.20.0.0/16"])

        #expect(draft.problems.isEmpty)
    }

    @Test
    func startsFromTheServiceBeingEdited() async throws {
        let work = try await ServiceCatalogFixtures.customService(name: "Work", domains: ["corp.example"])

        let draft = CustomServiceDraft(editing: work.profile)

        #expect(draft.identifier == work.id)
        #expect(draft.name == "Work")
        #expect(draft.domains == ["corp.example"])
        #expect(draft.networks.isEmpty)
    }
}
