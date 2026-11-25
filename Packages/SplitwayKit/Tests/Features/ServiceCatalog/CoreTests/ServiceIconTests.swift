import ServiceCatalog
import Testing

@Suite
struct ServiceIconTests {
    @Test
    func readsATintWrittenInHexadecimal() throws {
        let tint = try ServiceTint(hexadecimal: "#229ED9")

        #expect([tint.red, tint.green, tint.blue] == [0x22, 0x9E, 0xD9])
    }

    @Test(arguments: ["229ED9", "#229ED", "#GG9ED9", "#229ED9FF"])
    func rejectsAMalformedTint(_ text: String) {
        #expect(throws: ServiceIconError.malformedTint) {
            try ServiceTint(hexadecimal: text)
        }
    }

    @Test(arguments: ["", "ABC", " "])
    func rejectsAMonogramThatIsEmptyOrTooLong(_ monogram: String) throws {
        let tint = try ServiceTint(hexadecimal: "#000000")

        #expect(throws: ServiceIconError.malformedMonogram) {
            try ServiceIcon(monogram: monogram, tint: tint)
        }
    }
}
