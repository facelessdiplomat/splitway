import AppRouting
import Testing

@Suite
struct ServiceIdentifierTests {
    @Test
    func makesDistinctValidIdentifiersForCustomServices() throws {
        let first = ServiceIdentifier.forCustomService()
        let second = ServiceIdentifier.forCustomService()

        #expect(first != second)
        #expect(first.description.hasPrefix("custom-"))
        #expect(try ServiceIdentifier(first.description) == first)
    }
}
