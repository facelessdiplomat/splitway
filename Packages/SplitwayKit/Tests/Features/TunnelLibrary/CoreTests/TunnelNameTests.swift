import Testing
import TunnelLibrary

@Suite
struct TunnelNameTests {
    @Test(arguments: [("Office", "Office"), ("  Home VPN  ", "Home VPN"), ("Прага", "Прага"), ("cz-prg", "cz-prg")])
    func acceptsReadableNamesAndTrimsSurroundingSpaces(input: String, name: String) throws {
        #expect(try TunnelName(input).description == name)
    }

    @Test(arguments: ["", "   "])
    func rejectsEmptyNames(_ text: String) {
        #expect(throws: TunnelNameError.empty) {
            try TunnelName(text)
        }
    }

    @Test
    func rejectsNamesLongerThanTheLimit() throws {
        let longestName = String(repeating: "a", count: TunnelName.maximumLength)

        #expect(try TunnelName(longestName).description == longestName)
        #expect(throws: TunnelNameError.tooLong) {
            try TunnelName(longestName + "a")
        }
    }

    @Test(arguments: ["Office\nVPN", "Tab\tName", "Bell\u{7}"])
    func rejectsControlCharacters(_ text: String) {
        #expect(throws: TunnelNameError.containsControlCharacters) {
            try TunnelName(text)
        }
    }

    @Test(arguments: [
        ("office.conf", "office"),
        ("cz-prg.conf", "cz-prg"),
        ("my vpn (1).conf", "my vpn (1)"),
        ("/Users/me/Downloads/Прага.CONF", "Прага"),
        ("wg0", "wg0"),
        ("archive.tar.conf", "archive.tar"),
    ])
    func derivesNamesFromFileNames(fileName: String, name: String) {
        #expect(TunnelName.derived(fromFileName: fileName)?.description == name)
    }

    @Test(arguments: [".conf", "   .conf", ""])
    func derivesNothingFromFileNamesWithoutAName(_ fileName: String) {
        #expect(TunnelName.derived(fromFileName: fileName) == nil)
    }

    @Test
    func truncatesLongFileNamesToTheLimit() {
        let fileName = String(repeating: "b", count: TunnelName.maximumLength + 10) + ".conf"

        #expect(TunnelName.derived(fromFileName: fileName)?.description.count == TunnelName.maximumLength)
    }
}
