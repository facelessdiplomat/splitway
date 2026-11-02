import AppRouting
import ApplicationCatalog
import ApplicationCatalogPresentation
import ApplicationCatalogTestSupport
import Testing
import TunnelEditorPresentation

@MainActor
@Suite
struct TunnelEditorApplicationPickerTests {
    private let editorApplication = InstalledApplication.fixture(named: "Editor")

    @Test
    func offersThePickerOnceSelectedApplicationsAreRouted() async throws {
        let environment = TunnelEditorTestEnvironment()
        let tunnel = try await environment.storeTunnel(named: "Office")
        let editor = environment.editor(for: tunnel, choosingApplicationsWith: pickerActions())
        #expect(!editor.canChooseApplications)

        editor.routing.selectMode(.selectedApplications)

        #expect(editor.canChooseApplications)
    }

    @Test
    func offersNoPickerWithoutTheApplicationCatalog() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(for: try await environment.storeTunnel(named: "Office"))

        editor.routing.selectMode(.selectedApplications)
        editor.chooseApplications()

        #expect(!editor.canChooseApplications)
        #expect(editor.applicationPicker == nil)
    }

    @Test
    func opensThePickerWithTheApplicationsAlreadyRouted() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(
            for: try await environment.storeTunnel(named: "Office"),
            choosingApplicationsWith: pickerActions()
        )
        editor.routing.selectMode(.selectedApplications)
        let selection = ApplicationSelection([
            try ApplicationIdentity(kind: .application, displayName: "Editor", path: editorApplication.path)
        ])
        editor.routing.setApplications(selection)

        editor.chooseApplications()

        #expect(editor.applicationPicker?.selection == selection)
    }

    @Test
    func savesTheApplicationsChosenInThePicker() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(
            for: try await environment.storeTunnel(named: "Office"),
            choosingApplicationsWith: pickerActions()
        )
        editor.routing.selectMode(.selectedApplications)
        editor.chooseApplications()
        let picker = try #require(editor.applicationPicker)
        await picker.load()
        await picker.setSelected(true, path: editorApplication.path)

        editor.finishChoosingApplications()
        await editor.save()

        #expect(editor.applicationPicker == nil)
        #expect(environment.savedTunnels.map(\.routingPolicy.mode) == [.selectedApplications(picker.selection)])
        #expect(picker.selection.applications.map(\.path) == [editorApplication.path])
    }

    private func pickerActions() -> ApplicationPickerActions {
        ApplicationPickerActions(
            loadApplications: LoadInstalledApplicationsUseCase(
                scanner: InMemoryApplicationBundleScanner(applications: [editorApplication])),
            resolveIdentity: ResolveApplicationIdentityUseCase(
                signatures: InMemoryCodeSignatureReader(signaturesByPath: [:])),
            fileReader: InMemoryApplicationFileReader(),
            fileAccess: InMemoryChosenFileAccess(),
            iconLoader: InMemoryApplicationIconLoader()
        )
    }
}
