import SharedKernel
import Testing

@Suite
struct IPAddressParsingTests {
    @Test(arguments: [
        "0.0.0.0",
        "255.255.255.255",
        "10.14.0.2",
        "192.168.1.1",
    ])
    func parsesDottedDecimalIPv4(_ text: String) throws {
        let address = try IPAddress(text)

        #expect(address.family == .ipv4)
        #expect(address.description == text)
    }

    @Test(arguments: [
        "1.2.3",
        "1.2.3.4.5",
        "256.0.0.1",
        "01.2.3.4",
        "1..2.3",
        "1.2.3.",
        "+1.2.3.4",
        " 1.2.3.4",
        "1.2.3.4 ",
        "a.b.c.d",
        "١.٢.٣.٤",
    ])
    func rejectsMalformedIPv4(_ text: String) {
        #expect(throws: IPAddressParsingError.malformedIPv4) {
            try IPAddress(text)
        }
    }

    @Test(arguments: [
        "2001:db8::1",
        "::",
        "::1",
        "fe80::1:2",
        "1:2:3:4:5:6:7:8",
        "::ffff:192.0.2.1",
    ])
    func parsesIPv6(_ text: String) throws {
        let address = try IPAddress(text)

        #expect(address.family == .ipv6)
    }

    @Test(arguments: [
        ":",
        ":::",
        "1:::2",
        "1::2::3",
        "12345::",
        "1:2:3:4:5:6:7:8:9",
        "1:2:3:4:5:6:7",
        "1:2:3:4:5:6:7:8::",
        "g::1",
        "[::1]",
        "1.2.3.4::",
        "::1.2.3",
        "1:2:3:4:5:6:7:1.2.3.4",
        ":1::",
        "1::2:",
    ])
    func rejectsMalformedIPv6(_ text: String) {
        #expect(throws: IPAddressParsingError.malformedIPv6) {
            try IPAddress(text)
        }
    }

    @Test
    func rejectsEmptyText() {
        #expect(throws: IPAddressParsingError.empty) {
            try IPAddress("")
        }
    }

    @Test(arguments: ["fe80::1%en0", "fe80::1%25en0"])
    func rejectsZoneIdentifiers(_ text: String) {
        #expect(throws: IPAddressParsingError.zoneIdentifierNotSupported) {
            try IPAddress(text)
        }
    }
}
