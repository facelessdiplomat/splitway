import Testing
import TunnelLibraryPresentation

@MainActor
@Suite
struct TunnelListSearchTests {
    @Test
    func showsOnlyTunnelsWhoseNameMatchesTheSearch() async throws {
        let environment = TunnelListTestEnvironment()
        try await environment.storeTunnel(named: "Office")
        try await environment.storeTunnel(named: "Prague")
        try await environment.storeTunnel(named: "Home office")
        await environment.model.load()

        environment.model.searchText = "OFFICE"

        #expect(environment.model.visibleRows.map(\.name) == ["Office", "Home office"])
        #expect(environment.model.canReorder == false)
    }

    @Test(arguments: ["", "  "])
    func showsEveryTunnelWithoutASearch(searchText: String) async throws {
        let environment = TunnelListTestEnvironment()
        try await environment.storeTunnel(named: "Office")
        try await environment.storeTunnel(named: "Prague")
        await environment.model.load()

        environment.model.searchText = searchText

        #expect(environment.model.visibleRows.map(\.name) == ["Office", "Prague"])
        #expect(environment.model.canReorder)
    }

    @Test
    func tellsAnEmptySearchResultFromAnEmptyLibrary() async throws {
        let environment = TunnelListTestEnvironment()
        try await environment.storeTunnel(named: "Office")
        await environment.model.load()

        environment.model.searchText = "Prague"

        #expect(environment.model.visibleRows.isEmpty)
        #expect(environment.model.isEmpty == false)
        #expect(environment.model.hasNoSearchResults)
    }
}
