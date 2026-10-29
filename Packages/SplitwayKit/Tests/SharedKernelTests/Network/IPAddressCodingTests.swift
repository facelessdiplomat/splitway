import Foundation
import SharedKernel
import Testing

@Suite
struct IPAddressCodingTests {
    @Test
    func encodesTheCanonicalForm() throws {
        let encoded = try JSONEncoder().encode([try IPAddress("2001:0DB8::0001")])

        #expect(String(bytes: encoded, encoding: .utf8) == #"["2001:db8::1"]"#)
    }

    @Test
    func decodesValidAddresses() throws {
        let json = Data(#"["10.0.0.1","::1"]"#.utf8)

        let addresses = try JSONDecoder().decode([IPAddress].self, from: json)

        #expect(addresses == [try IPAddress("10.0.0.1"), try IPAddress("::1")])
    }

    @Test
    func rejectsInvalidAddressesWhenDecoding() {
        let json = Data(#"["10.0.0.256"]"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([IPAddress].self, from: json)
        }
    }
}
