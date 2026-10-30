import AppRouting
import ApplicationCatalog
import Foundation
import Observation

@MainActor
@Observable
public final class ApplicationPickerModel: Identifiable {
    public private(set) var selection: ApplicationSelection
    public private(set) var isLoading = false
    public private(set) var rejectedFileName: String?
    public var searchText = ""
    public var filter = ApplicationCatalogFilter.all

    private var scannedApplications: [InstalledApplication] = []
    private var resolvingPaths: Set<String> = []
    private let actions: ApplicationPickerActions
    private let didChangeSelection: @MainActor (ApplicationSelection) -> Void

    public init(
        selection: ApplicationSelection,
        actions: ApplicationPickerActions,
        didChangeSelection: @escaping @MainActor (ApplicationSelection) -> Void
    ) {
        self.selection = selection
        self.actions = actions
        self.didChangeSelection = didChangeSelection
    }

    public var iconLoader: any ApplicationIconLoader {
        actions.iconLoader
    }

    public var rows: [ApplicationPickerRow] {
        let identities = Dictionary(
            selection.applications.map { identity in (identity.path, identity) },
            uniquingKeysWith: { first, _ in first }
        )
        let query = ApplicationCatalogQuery(searchText: searchText, filter: filter)
        return query.results(in: listedApplications, selectedPaths: Set(identities.keys)).map { application in
            ApplicationPickerRow(
                application: application,
                isSelected: identities[application.path] != nil,
                isResolving: resolvingPaths.contains(application.path),
                remarks: ApplicationRemarkPolicy.remarks(for: application, identity: identities[application.path])
            )
        }
    }

    public func load() async {
        isLoading = true
        scannedApplications = await actions.loadApplications.execute()
        isLoading = false
    }

    public func setSelected(_ isSelected: Bool, path: String) async {
        guard isSelected else {
            deselect(path: path)
            return
        }
        guard let application = listedApplications.first(where: { application in application.path == path }) else {
            return
        }
        await select(application)
    }

    public func addApplication(at path: String) async {
        guard let application = await actions.fileReader.application(at: path) else {
            rejectedFileName = URL(filePath: path).lastPathComponent
            return
        }
        if !scannedApplications.contains(where: { scanned in scanned.path == application.path }) {
            scannedApplications.append(application)
        }
        await select(application)
    }

    public func addApplications(at paths: [String]) async {
        for path in paths {
            await addApplication(at: path)
        }
    }

    public func dismissRejectedFile() {
        rejectedFileName = nil
    }

    private var listedApplications: [InstalledApplication] {
        let scannedPaths = Set(scannedApplications.map(\.path))
        let missing = selection.applications
            .filter { identity in !scannedPaths.contains(identity.path) }
            .map(InstalledApplication.init(representing:))
        return scannedApplications + missing
    }

    private func select(_ application: InstalledApplication) async {
        guard !isSelected(path: application.path), resolvingPaths.insert(application.path).inserted else { return }
        let identity = try? await actions.resolveIdentity.execute(for: application)
        guard resolvingPaths.remove(application.path) != nil, let identity else { return }
        updateSelection(selection.applications + [identity])
    }

    private func deselect(path: String) {
        resolvingPaths.remove(path)
        guard isSelected(path: path) else { return }
        updateSelection(selection.applications.filter { identity in identity.path != path })
    }

    private func isSelected(path: String) -> Bool {
        selection.applications.contains { identity in identity.path == path }
    }

    private func updateSelection(_ applications: [ApplicationIdentity]) {
        selection = ApplicationSelection(applications)
        didChangeSelection(selection)
    }
}
