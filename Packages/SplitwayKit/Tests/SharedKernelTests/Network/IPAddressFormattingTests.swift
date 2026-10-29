import SharedKernel
import Testing

@Suite
struct IPAddressFormattingTests {
    @Test(arguments: [
        ("2001:db8::1", "2001:db8::1"),
        ("2001:0DB8:0000:0000:0000:0000:0000:0001", "2001:db8::1"),
        ("::", "::"),
        ("::1", "::1"),
        ("1::", "1::"),
        ("2001:db8:0:0:1:0:0:1", "2001:db8::1:0:0:1"),
        ("2001:0:0:1:0:0:0:1", "2001:0:0:1::1"),
        ("2001:db8:0:1:1:1:1:1", "2001:db8:0:1:1:1:1:1"),
        ("1:2:3:4:5:6:7::", "1:2:3:4:5:6:7:0"),
        ("::ffff:192.0.2.1", "::ffff:192.0.2.1"),
        ("::FFFF:C000:0201", "::ffff:192.0.2.1"),
        ("64:ff9b::192.0.2.33", "64:ff9b::c000:221"),
        ("1:2:3:4:5:6:1.2.3.4", "1:2:3:4:5:6:102:304"),
    ])
    func formatsIPv6Canonically(input: String, canonical: String) throws {
        let address = try IPAddress(input)

        #expect(address.description == canonical)
    }

    @Test
    func formatsNumericallyBuiltAddresses() {
        #expect(IPAddress.ipv4(0x0A0E_0002).description == "10.14.0.2")
        #expect(IPAddress.ipv6(1).description == "::1")
    }
}
