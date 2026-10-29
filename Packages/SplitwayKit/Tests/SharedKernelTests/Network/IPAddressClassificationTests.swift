import SharedKernel
import Testing

@Suite
struct IPAddressClassificationTests {
    @Test(arguments: ["127.0.0.1", "127.255.255.254", "::1"])
    func recognizesLoopbackAddresses(_ text: String) throws {
        #expect(try IPAddress(text).isLoopback)
    }

    @Test(arguments: ["169.254.10.20", "fe80::1", "febf::1"])
    func recognizesLinkLocalAddresses(_ text: String) throws {
        #expect(try IPAddress(text).isLinkLocal)
    }

    @Test(arguments: ["10.0.0.1", "172.16.0.1", "172.31.255.255", "192.168.0.1", "fc00::1", "fd12:3456::1"])
    func recognizesPrivateAddresses(_ text: String) throws {
        #expect(try IPAddress(text).isPrivate)
    }

    @Test(arguments: ["224.0.0.251", "239.255.255.250", "ff02::fb"])
    func recognizesMulticastAddresses(_ text: String) throws {
        #expect(try IPAddress(text).isMulticast)
    }

    @Test(arguments: ["8.8.8.8", "172.32.0.1", "192.169.0.1", "2001:4860:4860::8888", "fec0::1"])
    func leavesPublicAddressesUnclassified(_ text: String) throws {
        let address = try IPAddress(text)

        #expect(!address.isLoopback)
        #expect(!address.isLinkLocal)
        #expect(!address.isPrivate)
        #expect(!address.isMulticast)
    }

    @Test
    func definesWellKnownNetworksByTheirStandardRanges() {
        #expect(IPNetwork.loopbackNetworks.map(\.description) == ["127.0.0.0/8", "::1/128"])
        #expect(IPNetwork.linkLocalNetworks.map(\.description) == ["169.254.0.0/16", "fe80::/10"])
        #expect(
            IPNetwork.privateNetworks.map(\.description) == [
                "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "fc00::/7",
            ]
        )
        #expect(IPNetwork.multicastNetworks.map(\.description) == ["224.0.0.0/4", "ff00::/8"])
    }
}
