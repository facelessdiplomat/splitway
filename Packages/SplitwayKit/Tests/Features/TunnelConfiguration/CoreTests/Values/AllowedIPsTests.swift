import SharedKernel
import Testing
import TunnelConfiguration

@Suite
struct AllowedIPsTests {
    @Test
    func keepsNetworksAsWritten() throws {
        let networks = [try IPNetwork("10.0.0.1/24"), try IPNetwork("0.0.0.0/0")]

        #expect(AllowedIPs(networks).networks == networks)
    }

    @Test
    func exposesTheCoveredAddressesAsANormalizedSet() throws {
        let allowedIPs = AllowedIPs([try IPNetwork("10.0.0.0/25"), try IPNetwork("10.0.0.128/25")])

        #expect(allowedIPs.networkSet.networks.map(\.description) == ["10.0.0.0/24"])
    }

    @Test
    func knowsWhenNoNetworkIsAllowed() throws {
        #expect(AllowedIPs([]).isEmpty)
        #expect(!AllowedIPs([try IPNetwork("::/0")]).isEmpty)
    }
}
