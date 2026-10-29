import Testing
import TunnelLibrary

@Suite
struct UniqueTunnelNameResolverTests {
    @Test
    func keepsANameThatIsNotTaken() throws {
        let resolved = UniqueTunnelNameResolver.uniqueName(
            for: try TunnelName("Office"), takenNames: [try TunnelName("Home")])

        #expect(resolved.description == "Office")
    }

    @Test
    func appendsTheFirstFreeNumber() throws {
        let taken = try ["Office", "Office 2", "Office 4"].map { try TunnelName($0) }

        let resolved = UniqueTunnelNameResolver.uniqueName(for: try TunnelName("Office"), takenNames: taken)

        #expect(resolved.description == "Office 3")
    }

    @Test
    func comparesNamesWithoutRegardToCase() throws {
        let resolved = UniqueTunnelNameResolver.uniqueName(
            for: try TunnelName("office"), takenNames: [try TunnelName("OFFICE")])

        #expect(resolved.description == "office 2")
    }

    @Test
    func resolvesASeriesOfImportsOfTheSameFile() throws {
        var taken: [TunnelName] = []
        for _ in 0..<3 {
            taken.append(UniqueTunnelNameResolver.uniqueName(for: try TunnelName("cz-prg"), takenNames: taken))
        }

        #expect(taken.map(\.description) == ["cz-prg", "cz-prg 2", "cz-prg 3"])
    }

    @Test
    func shortensTheBaseNameToFitTheNumberWithinTheLimit() throws {
        let longestName = try TunnelName(String(repeating: "c", count: TunnelName.maximumLength))

        let resolved = UniqueTunnelNameResolver.uniqueName(for: longestName, takenNames: [longestName])

        #expect(resolved.description.count == TunnelName.maximumLength)
        #expect(resolved.description.hasSuffix(" 2"))
    }
}
