import Foundation

public struct ApplicationCatalogQuery: Sendable, Hashable {
    public var searchText: String
    public var filter: ApplicationCatalogFilter

    public init(searchText: String = "", filter: ApplicationCatalogFilter = .all) {
        self.searchText = searchText
        self.filter = filter
    }

    public func results(in applications: [InstalledApplication], selectedPaths: Set<String>) -> [InstalledApplication] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return
            applications
            .filter { application in passesFilter(application, selectedPaths: selectedPaths) }
            .filter { application in query.isEmpty || application.name.localizedStandardContains(query) }
            .sorted { first, second in first.name.localizedStandardCompare(second.name) == .orderedAscending }
    }

    private func passesFilter(_ application: InstalledApplication, selectedPaths: Set<String>) -> Bool {
        switch filter {
        case .all: true
        case .selected: selectedPaths.contains(application.path)
        case .commandLineTools: application.kind == .commandLineTool
        }
    }
}
