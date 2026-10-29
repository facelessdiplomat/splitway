import Testing
import TunnelConfiguration

@Suite
struct MTUTests {
    @Test(arguments: [576, 1_280, 1_420, 9_000])
    func acceptsValuesInTheSupportedRange(_ value: Int) throws {
        #expect(try MTU(value).value == value)
    }

    @Test(arguments: [0, 575, 9_001])
    func rejectsValuesOutsideTheSupportedRange(_ value: Int) {
        #expect(throws: MTUValidationError.outOfRange) {
            try MTU(value)
        }
    }

    @Test
    func parsesDecimalText() throws {
        #expect(try MTU("1420") == MTU(1_420))
    }

    @Test(arguments: ["", "01420", "abc", "+1420", "1420 "])
    func rejectsTextThatIsNotANumber(_ text: String) {
        #expect(throws: MTUValidationError.notANumber) {
            try MTU(text)
        }
    }

    @Test(arguments: ["100", "10000"])
    func rejectsNumericTextOutsideTheSupportedRange(_ text: String) {
        #expect(throws: MTUValidationError.outOfRange) {
            try MTU(text)
        }
    }
}
