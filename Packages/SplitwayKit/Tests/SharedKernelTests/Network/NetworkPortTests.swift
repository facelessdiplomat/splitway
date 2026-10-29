import Foundation
import SharedKernel
import Testing

@Suite
struct NetworkPortTests {
    @Test(arguments: [1, 53, 51_820, 65_535])
    func acceptsPortsInTheValidRange(_ number: Int) throws {
        #expect(try NetworkPort(number).value == UInt16(number))
    }

    @Test(arguments: [0, -1, 65_536, 100_000])
    func rejectsPortsOutsideTheValidRange(_ number: Int) {
        #expect(throws: NetworkPortValidationError.outOfRange) {
            try NetworkPort(number)
        }
    }

    @Test(arguments: [("51820", 51_820), ("1", 1), ("65535", 65_535)])
    func parsesDecimalText(text: String, number: Int) throws {
        #expect(try NetworkPort(text) == NetworkPort(number))
    }

    @Test(arguments: ["", "+80", "-80", "080", "80a", " 80", "８０"])
    func rejectsTextThatIsNotACanonicalNumber(_ text: String) {
        #expect(throws: NetworkPortValidationError.notANumber) {
            try NetworkPort(text)
        }
    }

    @Test(arguments: ["0", "65536", "99999"])
    func rejectsNumericTextOutsideTheValidRange(_ text: String) {
        #expect(throws: NetworkPortValidationError.outOfRange) {
            try NetworkPort(text)
        }
    }

    @Test
    func ordersPortsNumerically() throws {
        #expect(try NetworkPort(80) < NetworkPort(443))
    }

    @Test
    func describesItselfAsTheNumber() throws {
        #expect(try NetworkPort(51_820).description == "51820")
    }

    @Test
    func roundTripsThroughCodableAsANumber() throws {
        let ports = [try NetworkPort(51_820)]

        let encoded = try JSONEncoder().encode(ports)

        #expect(String(bytes: encoded, encoding: .utf8) == "[51820]")
        #expect(try JSONDecoder().decode([NetworkPort].self, from: encoded) == ports)
    }

    @Test
    func rejectsOutOfRangeNumbersWhenDecoding() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([NetworkPort].self, from: Data("[0]".utf8))
        }
    }
}
