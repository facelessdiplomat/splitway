import SharedKernel
import Testing

@Suite
struct IPAddressNetworkOrderBytesTests {
    @Test(arguments: [
        ("203.0.113.7", [203, 0, 113, 7] as [UInt8]),
        ("2001:db8::1", [0x20, 0x01, 0x0D, 0xB8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1] as [UInt8]),
    ])
    func convertsAnAddressToAndFromItsNetworkOrderBytes(text: String, bytes: [UInt8]) throws {
        let address = try IPAddress(text)

        #expect(address.networkOrderBytes == bytes)
        #expect(IPAddress(networkOrderBytes: bytes) == address)
    }

    @Test(arguments: [0, 3, 5, 15, 17])
    func rejectsBytesOfNeitherFamily(byteCount: Int) {
        #expect(IPAddress(networkOrderBytes: [UInt8](repeating: 1, count: byteCount)) == nil)
    }
}
