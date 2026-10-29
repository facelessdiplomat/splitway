import SharedKernel
import Testing
import TunnelConfiguration

@Suite
struct EndpointTests {
    @Test(arguments: [
        ("203.0.113.7:51820", "203.0.113.7:51820"),
        ("[2001:DB8::1]:51820", "[2001:db8::1]:51820"),
        ("vpn.example.com:51820", "vpn.example.com:51820"),
        ("VPN.Example.COM:443", "vpn.example.com:443"),
    ])
    func parsesAndFormatsEndpoints(input: String, canonical: String) throws {
        #expect(try Endpoint(input).description == canonical)
    }

    @Test
    func distinguishesAddressesFromNames() throws {
        #expect(try Endpoint("203.0.113.7:51820").host == .address(IPAddress("203.0.113.7")))
        #expect(try Endpoint("vpn.example.com:51820").host == .name(DomainName("vpn.example.com")))
        #expect(try Endpoint("vpn.example.com:51820").port == NetworkPort(51_820))
    }

    @Test(arguments: ["203.0.113.7", "vpn.example.com", "[2001:db8::1]"])
    func rejectsEndpointsWithoutAPort(_ text: String) {
        #expect(throws: EndpointParsingError.missingPort) {
            try Endpoint(text)
        }
    }

    @Test
    func rejectsIPv6WithoutBrackets() {
        #expect(throws: EndpointParsingError.unbracketedIPv6) {
            try Endpoint("2001:db8::1:51820")
        }
    }

    @Test(arguments: ["[203.0.113.7]:51820", "[2001:db8::1:51820", ":51820", "exa_mple.com:51820", "1.2.3.999:51820"])
    func rejectsInvalidHosts(_ text: String) {
        #expect(throws: EndpointParsingError.invalidHost) {
            try Endpoint(text)
        }
    }

    @Test
    func reportsWhyThePortIsInvalid() {
        #expect(throws: EndpointParsingError.invalidPort(.outOfRange)) {
            try Endpoint("vpn.example.com:0")
        }
        #expect(throws: EndpointParsingError.invalidPort(.notANumber)) {
            try Endpoint("vpn.example.com:http")
        }
    }
}
