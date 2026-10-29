import SharedKernel
import Testing

@Suite
struct IPAddressComparisonTests {
    @Test
    func ordersIPv4BeforeIPv6() throws {
        #expect(try IPAddress("255.255.255.255") < IPAddress("::"))
    }

    @Test(arguments: [
        ("9.255.255.255", "10.0.0.0"),
        ("10.0.0.1", "10.0.0.2"),
        ("2001:db8::1", "2001:db8::2"),
        ("::ffff:0.0.0.1", "fe80::"),
    ])
    func ordersAddressesOfOneFamilyNumerically(smaller: String, larger: String) throws {
        #expect(try IPAddress(smaller) < IPAddress(larger))
    }

    @Test
    func treatsDifferentSpellingsOfTheSameAddressAsEqual() throws {
        let compact = try IPAddress("2001:db8::1")
        let expanded = try IPAddress("2001:0DB8:0:0:0:0:0:1")

        #expect(compact == expanded)
        #expect(compact.hashValue == expanded.hashValue)
    }

    @Test
    func distinguishesIPv4FromIPv4MappedIPv6() throws {
        #expect(try IPAddress("192.0.2.1") != IPAddress("::ffff:192.0.2.1"))
    }
}
