import AppRouting
import ApplicationCatalog
import ApplicationCatalogPresentation
import ApplicationCatalogTestSupport
import Foundation
import Testing

@MainActor
@Suite
struct ApplicationPickerModelTests {
    private static let developerTeam = "ABCDE12345"

    private let editor = InstalledApplication.fixture(named: "Editor")
    private let probe = InstalledApplication.fixture(named: "probe", kind: .commandLineTool, version: nil)
    private let mail = InstalledApplication(
        kind: .application,
        name: "Mail",
        bundleIdentifier: "com.apple.mail",
        path: "/System/Applications/Mail.app",
        version: "16.0"
    )
    private let reports = SelectionReports()

    @Test
    func listsInstalledApplicationsByName() async {
        let installed = ["Zebra", "Editor", "App 10", "App 2"].map { name in InstalledApplication.fixture(named: name) }
        let model = picker(installed: installed)

        await model.load()

        #expect(model.rows.map(\.application.name) == ["App 2", "App 10", "Editor", "Zebra"])
    }

    @Test
    func checksTheApplicationsThatAreAlreadySelected() async throws {
        let model = picker(installed: [editor, mail], selection: ApplicationSelection([try identity(of: editor)]))

        await model.load()

        #expect(model.rows.map(\.isSelected) == [true, false])
    }

    @Test
    func selectingAnApplicationAddsTheIdentityFromItsSignatures() async throws {
        let signatures = BundleCodeSignatures(
            main: CodeSignature(signingIdentifier: "com.example.editor", teamIdentifier: Self.developerTeam),
            nested: [CodeSignature(signingIdentifier: "com.example.editor.helper", teamIdentifier: Self.developerTeam)]
        )
        let model = picker(installed: [editor], signatures: [editor.path: signatures])
        await model.load()

        await model.setSelected(true, path: editor.path)

        let selected = try #require(model.selection.applications.first)
        #expect(selected.signingIdentifiers == ["com.example.editor", "com.example.editor.helper"])
        #expect(selected.teamIdentifier == Self.developerTeam)
        #expect(reports.selections == [model.selection])
    }

    @Test
    func deselectingAnApplicationRemovesItFromTheSelection() async throws {
        let model = picker(installed: [editor], selection: ApplicationSelection([try identity(of: editor)]))
        await model.load()

        await model.setSelected(false, path: editor.path)

        #expect(model.selection.isEmpty)
        #expect(reports.selections == [ApplicationSelection([])])
    }

    @Test
    func keepsListingASelectedApplicationThatIsNoLongerInstalled() async throws {
        let removed = try ApplicationIdentity(kind: .application, displayName: "Old", path: "/Volumes/Disk/Old.app")
        let model = picker(installed: [editor], selection: ApplicationSelection([removed]))
        await model.load()

        model.filter = .selected

        #expect(model.rows.map(\.application.name) == ["Old"])
        #expect(model.rows.map(\.isSelected) == [true])
    }

    @Test
    func addsACommandLineToolFromAFile() async {
        let model = picker(installed: [editor], files: [probe])
        await model.load()

        await model.addApplication(at: probe.path)
        model.filter = .commandLineTools

        #expect(model.selection.applications.map(\.path) == [probe.path])
        #expect(model.rows.map(\.application.name) == ["probe"])
        #expect(model.rows.map(\.isSelected) == [true])
    }

    @Test
    func selectsAnAddedApplicationThatIsAlreadyListedWithoutRepeatingIt() async {
        let model = picker(installed: [editor], files: [editor])
        await model.load()

        await model.addApplication(at: editor.path)

        #expect(model.rows.map(\.application.name) == ["Editor"])
        #expect(model.rows.map(\.isSelected) == [true])
    }

    @Test
    func reportsAFileThatIsNotAnApplication() async {
        let model = picker(installed: [editor])
        await model.load()

        await model.addApplication(at: "/Users/someone/notes.txt")

        #expect(model.rejectedFileName == "notes.txt")
        #expect(model.selection.isEmpty)
        #expect(reports.selections.isEmpty)
        model.dismissRejectedFile()
        #expect(model.rejectedFileName == nil)
    }

    @Test
    func keepsAccessToAChosenFileUntilItIsAddedAndThenClosesIt() async {
        let homemade = InstalledApplication(
            kind: .application,
            name: "Homemade",
            bundleIdentifier: "com.example.homemade",
            path: "/Users/someone/Desktop/Homemade.app",
            version: "1.0"
        )
        let signatures = BundleCodeSignatures(
            main: CodeSignature(signingIdentifier: "com.example.homemade", teamIdentifier: Self.developerTeam),
            nested: []
        )
        let access = InMemoryChosenFileAccess()
        let model = picker(
            installed: [editor], signatures: [homemade.path: signatures], files: [homemade], access: access)
        await model.load()

        await model.addApplications([URL(filePath: homemade.path)])

        #expect(model.selection.applications.map(\.path) == [homemade.path])
        #expect(access.openPaths.isEmpty)
    }

    @Test
    func marksAppleApplicationsAndApplicationsMatchedByPath() async {
        let homemade = InstalledApplication.fixture(named: "Homemade")
        let adHocSignature = BundleCodeSignatures(
            main: CodeSignature(signingIdentifier: "Homemade-5555494495d1", teamIdentifier: nil),
            nested: []
        )
        let model = picker(installed: [homemade, mail], signatures: [homemade.path: adHocSignature])
        await model.load()

        await model.setSelected(true, path: homemade.path)

        #expect(model.rows.map(\.remarks) == [[.matchedByPath], [.appleApplication]])
    }

    @Test
    func searchesApplicationsByName() async {
        let model = picker(installed: [editor, mail])
        await model.load()

        model.searchText = "edi"

        #expect(model.rows.map(\.application.name) == ["Editor"])
    }

    private func picker(
        installed: [InstalledApplication],
        selection: ApplicationSelection = ApplicationSelection([]),
        signatures: [String: BundleCodeSignatures] = [:],
        files: [InstalledApplication] = [],
        access: InMemoryChosenFileAccess? = nil
    ) -> ApplicationPickerModel {
        let actions = ApplicationPickerActions(
            loadApplications: LoadInstalledApplicationsUseCase(
                scanner: InMemoryApplicationBundleScanner(applications: installed)),
            resolveIdentity: ResolveApplicationIdentityUseCase(
                signatures: InMemoryCodeSignatureReader(signaturesByPath: signatures, readableWhileOpenIn: access)),
            fileReader: InMemoryApplicationFileReader(applications: files, readableWhileOpenIn: access),
            fileAccess: access ?? InMemoryChosenFileAccess(),
            iconLoader: InMemoryApplicationIconLoader()
        )
        return ApplicationPickerModel(selection: selection, actions: actions) { [reports] selection in
            reports.selections.append(selection)
        }
    }

    private func identity(of application: InstalledApplication) throws -> ApplicationIdentity {
        try ApplicationIdentity(kind: application.kind, displayName: application.name, path: application.path)
    }
}

@MainActor
private final class SelectionReports {
    var selections: [ApplicationSelection] = []
}
