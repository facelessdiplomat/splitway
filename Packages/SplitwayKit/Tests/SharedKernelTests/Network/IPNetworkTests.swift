import Foundation
import SharedKernel
import Testing

@Suite
struct IPNetworkTests {
    @Test(arguments: [
        ("10.14.0.2/16", "10.14.0.2/16"),
        ("0.0.0.0/0", "0.0.0.0/0"),
        ("192.168.1.1", "192.168.1.1/32"),
        ("2001:DB8::/32", "2001:db8::/32"),
        ("::1", "::1/128"),
        ("::/0", "::/0"),
    ])
    func parsesNetworksAndDefaultsToTheFullPrefix(input: String, canonical: String) throws {
        let network = try IPNetwork(input)

        #expect(network.description == canonical)
    }

    @Test(arguments: ["10.0.0.0/33", "::/129"])
    func rejectsPrefixLengthsBeyondTheAddressWidth(_ text: String) {
        #expect(throws: IPNetworkParsingError.prefixLengthOutOfRange) {
            try IPNetwork(text)
        }
    }

    @Test(arguments: ["10.0.0.0/", "10.0.0.0/08", "10.0.0.0/+8", "10.0.0.0/8/9", "10.0.0.0/a", "10.0.0.0/1000"])
    func rejectsMalformedPrefixLengths(_ text: String) {
        #expect(throws: IPNetworkParsingError.malformedPrefixLength) {
            try IPNetwork(text)
        }
    }

    @Test
    func reportsTheReasonForInvalidAddresses() {
        #expect(throws: IPNetworkParsingError.invalidAddress(.malformedIPv4)) {
            try IPNetwork("10.0.0.256/8")
        }
        #expect(throws: IPNetworkParsingError.invalidAddress(.empty)) {
            try IPNetwork("/8")
        }
    }

    @Test
    func keepsInterfaceAddressesAsWrittenAndNormalizesOnRequest() throws {
        let interfaceAddress = try IPNetwork("10.14.0.2/16")

        #expect(interfaceAddress.hasHostBits)
        #expect(interfaceAddress.normalized.description == "10.14.0.0/16")
        #expect(interfaceAddress != interfaceAddress.normalized)
    }

    @Test
    func exposesTheFirstAndLastAddresses() throws {
        let network = try IPNetwork("172.16.5.4/12")

        #expect(network.firstAddress.description == "172.16.0.0")
        #expect(network.lastAddress.description == "172.31.255.255")
    }

    @Test(arguments: [
        ("10.0.0.0/8", "10.255.255.255", true),
        ("10.0.0.0/8", "11.0.0.0", false),
        ("0.0.0.0/0", "203.0.113.7", true),
        ("0.0.0.0/0", "::1", false),
        ("2001:db8::/32", "2001:db8:ffff::1", true),
        ("fe80::/10", "fec0::", false),
    ])
    func checksWhetherAnAddressBelongsToTheNetwork(network: String, address: String, isContained: Bool) throws {
        #expect(try IPNetwork(network).contains(IPAddress(address)) == isContained)
    }

    @Test(arguments: [
        ("10.0.0.0/8", "10.1.0.0/16", true),
        ("10.1.0.0/16", "10.0.0.0/8", false),
        ("10.0.0.0/8", "10.0.0.0/8", true),
        ("10.0.0.0/8", "11.0.0.0/8", false),
    ])
    func checksWhetherANetworkIsNested(outer: String, inner: String, isContained: Bool) throws {
        #expect(try IPNetwork(outer).contains(IPNetwork(inner)) == isContained)
    }

    @Test(arguments: [
        ("10.0.0.0/8", "10.1.0.0/16", true),
        ("10.1.0.0/16", "10.0.0.0/8", true),
        ("10.0.0.0/9", "10.128.0.0/9", false),
        ("0.0.0.0/0", "::/0", false),
    ])
    func detectsOverlappingNetworks(first: String, second: String, overlaps: Bool) throws {
        #expect(try IPNetwork(first).overlaps(IPNetwork(second)) == overlaps)
    }

    @Test
    func roundTripsThroughCodable() throws {
        let networks = [try IPNetwork("10.14.0.2/16"), try IPNetwork("::/0")]

        let decoded = try JSONDecoder().decode([IPNetwork].self, from: JSONEncoder().encode(networks))

        #expect(decoded == networks)
    }
}
