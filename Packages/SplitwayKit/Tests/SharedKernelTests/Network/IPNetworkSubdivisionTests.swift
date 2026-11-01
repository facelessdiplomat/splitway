import SharedKernel
import Testing

@Suite
struct IPNetworkSubdivisionTests {
    @Test
    func splitsANetworkIntoItsTwoHalves() throws {
        let network = try IPNetwork("198.18.0.0/15")

        #expect(network.halves == [try IPNetwork("198.18.0.0/16"), try IPNetwork("198.19.0.0/16")])
    }

    @Test
    func cannotSplitASingleAddress() throws {
        let host = try IPNetwork("10.0.0.1/32")

        #expect(host.halves.isEmpty)
    }

    @Test
    func findsAnAddressByItsOffsetInsideTheNetwork() throws {
        let ipv4 = try IPNetwork("198.18.0.0/15")
        let ipv6 = try IPNetwork("2001:2::/48")

        #expect(ipv4.address(atOffset: 2) == (try IPAddress("198.18.0.2")))
        #expect(ipv6.address(atOffset: 2) == (try IPAddress("2001:2::2")))
    }

    @Test
    func findsNoAddressBeyondTheNetwork() throws {
        let network = try IPNetwork("192.0.2.0/30")

        #expect(network.address(atOffset: 4) == nil)
    }

    @Test
    func knowsTheBenchmarkingNetworks() throws {
        #expect(IPNetwork.ipv4BenchmarkingRange == (try IPNetwork("198.18.0.0/15")))
        #expect(IPNetwork.ipv6BenchmarkingRange == (try IPNetwork("2001:2::/48")))
    }
}
