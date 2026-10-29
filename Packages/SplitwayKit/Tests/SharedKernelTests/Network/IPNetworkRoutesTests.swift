import SharedKernel
import Testing

@Suite
struct IPNetworkRoutesTests {
    @Test
    func definesTheDefaultRoutesOfBothFamilies() {
        #expect(IPNetwork.ipv4DefaultRoute.description == "0.0.0.0/0")
        #expect(IPNetwork.ipv6DefaultRoute.description == "::/0")
    }

    @Test
    func definesTheReservedIPv4Range() {
        #expect(IPNetwork.reservedNetworks.map(\.description) == ["240.0.0.0/4"])
    }
}
