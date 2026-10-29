import SharedKernel
import Testing

@Suite
struct CanonicalDecimalTextTests {
    @Test(arguments: [("0", 0), ("7", 7), ("1420", 1_420), ("999999999", 999_999_999)])
    func readsCanonicalDecimalNumbers(text: String, value: Int) {
        #expect(CanonicalDecimalText.integerValue(of: text) == value)
    }

    @Test(arguments: ["", "01", "+1", "-1", "1 ", "1e3", "١", "1000000000"])
    func rejectsTextThatIsNotACanonicalDecimalNumber(_ text: String) {
        #expect(CanonicalDecimalText.integerValue(of: text) == nil)
    }

    @Test
    func limitsTheNumberOfDigits() {
        #expect(CanonicalDecimalText.isCanonical("255", maximumDigits: 3))
        #expect(!CanonicalDecimalText.isCanonical("1000", maximumDigits: 3))
    }
}
