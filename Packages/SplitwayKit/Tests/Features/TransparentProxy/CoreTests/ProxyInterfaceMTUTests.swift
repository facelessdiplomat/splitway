import Testing
import TransparentProxy
import TunnelConfiguration

@Suite
struct ProxyInterfaceMTUTests {
    @Test
    func keepsTheMTUOfTheConfiguration() throws {
        let mtu = try ProxyInterfaceMTU.mtu(configured: MTU(1_380), pathMTU: 1_500, carriesIPv6: false)

        #expect(mtu == (try MTU(1_380)))
    }

    @Test(arguments: zip([1_500, 1_492, 1_400, 1_280], [1_420, 1_412, 1_320, 1_200]))
    func leavesRoomForWireGuardOnThePath(pathMTU: Int, expected: Int) throws {
        let mtu = try ProxyInterfaceMTU.mtu(configured: nil, pathMTU: pathMTU, carriesIPv6: false)

        #expect(mtu == (try MTU(expected)))
    }

    @Test
    func keepsTheIPv6MinimumForATunnelThatCarriesIPv6() throws {
        let mtu = try ProxyInterfaceMTU.mtu(configured: nil, pathMTU: 1_280, carriesIPv6: true)

        #expect(mtu == (try MTU(1_280)))
    }

    @Test
    func staysAtTheStandardMTUOnAJumboPath() throws {
        let mtu = try ProxyInterfaceMTU.mtu(configured: nil, pathMTU: 9_000, carriesIPv6: false)

        #expect(mtu == (try MTU(1_420)))
    }

    @Test
    func takesTheStandardMTUWithoutAPathMTU() throws {
        let mtu = try ProxyInterfaceMTU.mtu(configured: nil, pathMTU: nil, carriesIPv6: false)

        #expect(mtu == (try MTU(1_420)))
    }

    @Test
    func neverGoesBelowTheSmallestMTU() throws {
        let mtu = try ProxyInterfaceMTU.mtu(configured: nil, pathMTU: 600, carriesIPv6: false)

        #expect(mtu == (try MTU(576)))
    }
}
