import ApplicationCatalog
import ApplicationCatalogTestSupport
import Testing

@Suite
struct ApplicationCatalogQueryTests {
    private static let applications: [InstalledApplication] = [
        .fixture(named: "Terminal"),
        .fixture(named: "Café Notes"),
        .fixture(named: "curl", kind: .commandLineTool),
        .fixture(named: "App 10"),
        .fixture(named: "App 2"),
    ]

    @Test
    func findsApplicationsWhateverTheirCaseAndDiacritics() {
        let cafe = ApplicationCatalogQuery(searchText: "cafe")
        let terminal = ApplicationCatalogQuery(searchText: "  TERM ")

        #expect(cafe.results(in: Self.applications, selectedPaths: []).map(\.name) == ["Café Notes"])
        #expect(terminal.results(in: Self.applications, selectedPaths: []).map(\.name) == ["Terminal"])
    }

    @Test
    func showsSelectedApplicationsOrCommandLineToolsAlone() {
        let selected = ApplicationCatalogQuery(filter: .selected)
        let tools = ApplicationCatalogQuery(filter: .commandLineTools)
        let selectedPaths: Set<String> = ["/Applications/Terminal.app", "/usr/local/bin/curl"]

        #expect(
            selected.results(in: Self.applications, selectedPaths: selectedPaths).map(\.name) == ["curl", "Terminal"])
        #expect(tools.results(in: Self.applications, selectedPaths: selectedPaths).map(\.name) == ["curl"])
    }

    @Test
    func sortsByNameLikeTheFinder() {
        let all = ApplicationCatalogQuery()

        #expect(
            all.results(in: Self.applications, selectedPaths: []).map(\.name) == [
                "App 2", "App 10", "Café Notes", "curl", "Terminal",
            ])
    }
}
