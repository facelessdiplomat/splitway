import AppRouting
import Testing

@Suite
struct ServiceIdentifierTests {
    @Test(arguments: ["telegram", "youtube", "custom-7f3a"])
    func acceptsServiceIdentifiers(_ text: String) throws {
        #expect(try ServiceIdentifier(text).description == text)
    }

    @Test(arguments: ["", "Telegram", "you tube", "-telegram", "telegram-", "telegram_web"])
    func rejectsMalformedServiceIdentifiers(_ text: String) {
        #expect(throws: ServiceIdentifierError.malformed) {
            try ServiceIdentifier(text)
        }
    }

    @Test
    func rejectsAnIdentifierLongerThanSixtyFourCharacters() {
        #expect(throws: ServiceIdentifierError.malformed) {
            try ServiceIdentifier(String(repeating: "a", count: 65))
        }
    }

    @Test
    func makesDistinctValidIdentifiersForCustomServices() throws {
        let first = ServiceIdentifier.forCustomService()
        let second = ServiceIdentifier.forCustomService()

        #expect(first != second)
        #expect(first.description.hasPrefix("custom-"))
        #expect(try ServiceIdentifier(first.description) == first)
    }

    @Test
    func keepsTheFirstOfRepeatedServicesInASelection() throws {
        let telegram = try ServiceIdentifier("telegram")
        let youtube = try ServiceIdentifier("youtube")

        let selection = ServiceSelection([telegram, youtube, telegram])

        #expect(selection.services == [telegram, youtube])
    }
}
