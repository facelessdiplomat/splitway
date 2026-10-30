import RoutingProbeCore
import Testing

@Suite
struct DNSQueryTests {
    @Test
    func asksForTheAddressOfANameWithRecursion() throws {
        let query = try DNSQuery(identifier: 0x1234, name: "whoami.akamai.net")

        let expectedHeader: [UInt8] = [0x12, 0x34, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        let expectedQuestion: [UInt8] =
            [6] + Array("whoami".utf8) + [6] + Array("akamai".utf8) + [3] + Array("net".utf8) + [0, 0, 1, 0, 1]
        #expect(query.bytes == expectedHeader + expectedQuestion)
    }

    @Test(arguments: ["", "example..com", String(repeating: "a", count: 64) + ".com"])
    func rejectsAnInvalidName(_ name: String) {
        #expect(throws: DNSQueryError.invalidName) {
            try DNSQuery(identifier: 1, name: name)
        }
    }
}
