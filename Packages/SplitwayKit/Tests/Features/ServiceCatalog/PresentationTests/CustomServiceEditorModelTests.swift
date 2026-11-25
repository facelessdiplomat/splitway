import ServiceCatalog
import ServiceCatalogPresentation
import ServiceCatalogTestSupport
import Testing

@MainActor
@Suite
struct CustomServiceEditorModelTests {
    @Test
    func needsANameAndARuleBeforeSaving() {
        let editor = Self.editor()
        #expect(!editor.canSave)

        editor.name = "Work"
        let canSaveWithoutRules = editor.canSave
        editor.domainsText = "corp.example"

        #expect(!canSaveWithoutRules)
        #expect(editor.canSave)
    }

    @Test
    func pointsAtEntriesThatAreNeitherDomainsNorNetworks() {
        let editor = Self.editor()
        editor.name = "Work"

        editor.domainsText = "corp.example\nnot a domain, t.me"
        editor.networksText = "10.0.0.0/33\n10.20.0.0/16"

        #expect(editor.invalidDomains == ["not a domain"])
        #expect(editor.invalidNetworks == ["10.0.0.0/33"])
        #expect(!editor.canSave)
    }

    @Test
    func savesTheServiceAndHandsItBack() async {
        let repository = InMemoryCustomServiceRepository()
        var saved: [CustomService] = []
        let editor = CustomServiceEditorModel(save: SaveCustomServiceUseCase(repository: repository)) { service in
            saved.append(service)
        }
        editor.name = "Work"
        editor.domainsText = "corp.example"
        editor.networksText = "10.20.0.0/16"

        await editor.save()

        #expect(saved.map(\.name) == ["Work"])
        #expect(await repository.services == saved)
    }

    @Test
    func keepsTheIdentifierOfTheServiceItEdits() async throws {
        let work = try await ServiceCatalogFixtures.customService(name: "Work")
        let repository = InMemoryCustomServiceRepository(services: [work])
        var saved: [CustomService] = []
        let save = SaveCustomServiceUseCase(repository: repository)
        let editor = CustomServiceEditorModel(editing: work.profile, save: save) { service in
            saved.append(service)
        }
        let initialDomains = editor.domainsText

        editor.name = "Office"
        await editor.save()

        #expect(initialDomains == "corp.example")
        #expect(saved.map(\.id) == [work.id])
        #expect(saved.map(\.name) == ["Office"])
    }

    @Test
    func staysOpenWithTheReasonWhenTheServiceCannotBeStored() async {
        var saved: [CustomService] = []
        let save = SaveCustomServiceUseCase(repository: UnavailableCustomServiceRepository())
        let editor = CustomServiceEditorModel(save: save) { service in
            saved.append(service)
        }
        editor.name = "Work"
        editor.domainsText = "corp.example"

        await editor.save()

        #expect(editor.saveFailure == .storageUnavailable)
        #expect(saved.isEmpty)
    }

    private static func editor() -> CustomServiceEditorModel {
        CustomServiceEditorModel(save: SaveCustomServiceUseCase(repository: InMemoryCustomServiceRepository())) { _ in }
    }
}
