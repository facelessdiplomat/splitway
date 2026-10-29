import SharedKernel
import Testing

@Suite
struct IPNetworkSetTests {
    private static let publicUnicastIPv4Networks = [
        "0.0.0.0/5", "8.0.0.0/7", "11.0.0.0/8", "12.0.0.0/6", "16.0.0.0/4", "32.0.0.0/3", "64.0.0.0/2",
        "128.0.0.0/3", "160.0.0.0/5", "168.0.0.0/6", "172.0.0.0/12", "172.32.0.0/11", "172.64.0.0/10",
        "172.128.0.0/9", "173.0.0.0/8", "174.0.0.0/7", "176.0.0.0/4", "192.0.0.0/9", "192.128.0.0/11",
        "192.160.0.0/13", "192.169.0.0/16", "192.170.0.0/15", "192.172.0.0/14", "192.176.0.0/12",
        "192.192.0.0/10", "193.0.0.0/8", "194.0.0.0/7", "196.0.0.0/6", "200.0.0.0/5", "208.0.0.0/4",
    ]

    @Test
    func excludesPrivateAndMulticastIPv4NetworksLikeTheOfficialClient() throws {
        let excluded = try networkSet("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "224.0.0.0/3")

        let remaining = try networkSet("0.0.0.0/0").subtracting(excluded)

        #expect(descriptions(of: remaining) == Self.publicUnicastIPv4Networks)
    }

    @Test
    func subtractsUniqueLocalAddressesFromTheWholeIPv6Space() throws {
        let remaining = try networkSet("::/0").subtracting(networkSet("fc00::/7"))

        #expect(
            descriptions(of: remaining) == [
                "::/1", "8000::/2", "c000::/3", "e000::/4", "f000::/5", "f800::/6", "fe00::/7",
            ]
        )
    }

    @Test
    func decomposesAnUnalignedRangeIntoMinimalNetworks() throws {
        let remaining = try networkSet("10.0.0.0/29").subtracting(networkSet("10.0.0.0/32", "10.0.0.7/32"))

        #expect(descriptions(of: remaining) == ["10.0.0.1/32", "10.0.0.2/31", "10.0.0.4/31", "10.0.0.6/32"])
    }

    @Test
    func mergesOverlappingAndAdjacentNetworks() throws {
        let merged = try networkSet("10.0.0.0/25", "10.0.0.128/25", "10.0.0.64/26")

        #expect(descriptions(of: merged) == ["10.0.0.0/24"])
    }

    @Test
    func normalizesHostBitsOfInputNetworks() throws {
        #expect(try descriptions(of: networkSet("10.14.0.2/16")) == ["10.14.0.0/16"])
    }

    @Test
    func intersectsSets() throws {
        let first = try networkSet("10.0.0.0/8", "192.168.0.0/16")
        let second = try networkSet("10.20.0.0/16", "192.168.1.0/24", "172.16.0.0/12")

        #expect(descriptions(of: first.intersection(second)) == ["10.20.0.0/16", "192.168.1.0/24"])
    }

    @Test
    func keepsFamiliesSeparateAndListsIPv4First() throws {
        let everything = try networkSet("::/0", "0.0.0.0/0")

        #expect(descriptions(of: everything) == ["0.0.0.0/0", "::/0"])
        #expect(try descriptions(of: everything.subtracting(networkSet("0.0.0.0/0"))) == ["::/0"])
    }

    @Test
    func answersMembershipQueries() throws {
        let set = try networkSet("10.0.0.0/8", "2001:db8::/32")
        let insideAddress = try IPAddress("10.1.2.3")
        let outsideAddress = try IPAddress("11.0.0.1")
        let nestedNetwork = try IPNetwork("2001:db8:1::/48")
        let widerNetwork = try IPNetwork("2001:db8::/31")

        #expect(set.contains(insideAddress))
        #expect(!set.contains(outsideAddress))
        #expect(set.contains(nestedNetwork))
        #expect(!set.contains(widerNetwork))
    }

    @Test
    func treatsSetsCoveringTheSameAddressesAsEqual() throws {
        #expect(try networkSet("10.0.0.0/25", "10.0.0.128/25") == networkSet("10.0.0.0/24"))
    }

    @Test
    func reportsEmptiness() throws {
        #expect(IPNetworkSet().isEmpty)
        #expect(try networkSet("10.0.0.0/8").subtracting(networkSet("0.0.0.0/0")).isEmpty)
    }

    @Test
    func describesItselfAsCommaSeparatedNetworks() throws {
        #expect(try networkSet("::/0", "10.0.0.0/8").description == "10.0.0.0/8, ::/0")
    }

    private func networkSet(_ networks: String...) throws -> IPNetworkSet {
        IPNetworkSet(try networks.map { try IPNetwork($0) })
    }

    private func descriptions(of set: IPNetworkSet) -> [String] {
        set.networks.map(\.description)
    }
}
