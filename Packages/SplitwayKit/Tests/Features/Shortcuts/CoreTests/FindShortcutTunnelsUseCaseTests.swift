import Shortcuts
import Testing
import TunnelLibrary

@Suite
struct FindShortcutTunnelsUseCaseTests {
    @Test
    func listsEveryTunnelInTheOrderOfTheLibrary() async throws {
        let office = try ShortcutTestLibrary.record(named: "Office")
        let home = try ShortcutTestLibrary.record(named: "Home")
        let library = ShortcutTestLibrary(readable: [office, home])

        let tunnels = try await library.find.all()

        #expect(tunnels == [office, home])
    }

    @Test
    func listsNothingWhenTheLibraryIsEmpty() async throws {
        let library = ShortcutTestLibrary(readable: [])

        let tunnels = try await library.find.all()

        #expect(tunnels.isEmpty)
    }

    @Test
    func findsTunnelsByPartOfTheirNameIgnoringCase() async throws {
        let prague = try ShortcutTestLibrary.record(named: "Prague Office")
        let berlin = try ShortcutTestLibrary.record(named: "Berlin")
        let library = ShortcutTestLibrary(readable: [prague, berlin])

        let tunnels = try await library.find.tunnels(matching: "office")

        #expect(tunnels == [prague])
    }

    @Test
    func findsNothingWhenNoNameMatches() async throws {
        let library = ShortcutTestLibrary(readable: [try ShortcutTestLibrary.record(named: "Berlin")])

        let tunnels = try await library.find.tunnels(matching: "Tokyo")

        #expect(tunnels.isEmpty)
    }

    @Test
    func returnsTheKnownTunnelsForTheRequestedIdentifiers() async throws {
        let office = try ShortcutTestLibrary.record(named: "Office")
        let home = try ShortcutTestLibrary.record(named: "Home")
        let library = ShortcutTestLibrary(readable: [office, home])

        let tunnels = try await library.find.tunnels(identifiedBy: [home.id, TunnelIdentifier(), office.id])

        #expect(tunnels == [home, office])
    }
}
