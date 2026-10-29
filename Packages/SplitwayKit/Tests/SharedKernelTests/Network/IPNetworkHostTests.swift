import SharedKernel
import Testing

@Suite
struct IPNetworkHostTests {
    @Test(arguments: ["192.0.2.7", "2001:db8::7"])
    func coversExactlyTheGivenAddress(_ text: String) throws {
        let address = try IPAddress(text)

        let host = IPNetwork(host: address)

        #expect(host.address == address)
        #expect(host.prefixLength == address.family.bitWidth)
        #expect(host.firstAddress == host.lastAddress)
    }
}
