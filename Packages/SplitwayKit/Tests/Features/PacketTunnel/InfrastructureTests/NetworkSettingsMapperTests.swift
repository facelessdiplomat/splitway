import NetworkExtension
import PacketTunnel
import PacketTunnelInfrastructure
import SharedKernel
import Testing
import TunnelConfiguration

@Suite
struct NetworkSettingsMapperTests {
    @Test
    func mapsIPv4AddressesMasksAndRoutes() throws {
        let settings = NetworkSettingsMapper.settings(for: try Self.dualStackPlan())

        #expect(settings.ipv4Settings?.addresses == ["10.14.0.2"])
        #expect(settings.ipv4Settings?.subnetMasks == ["255.255.0.0"])
        #expect(
            settings.ipv4Settings?.includedRoutes?.map { route in
                "\(route.destinationAddress)/\(route.destinationSubnetMask)"
            }
                == ["0.0.0.0/0.0.0.0", "192.168.5.0/255.255.255.0"]
        )
    }

    @Test
    func mapsIPv6AddressesPrefixesAndRoutes() throws {
        let settings = NetworkSettingsMapper.settings(for: try Self.dualStackPlan())

        #expect(settings.ipv6Settings?.addresses == ["fd00::2"])
        #expect(settings.ipv6Settings?.networkPrefixLengths == [64])
        #expect(
            settings.ipv6Settings?.includedRoutes?.map { route in
                "\(route.destinationAddress)/\(route.destinationNetworkPrefixLength)"
            } == ["::/0"]
        )
    }

    @Test
    func sendsEveryDomainToTheTunnelDNSServers() throws {
        let settings = NetworkSettingsMapper.settings(for: try Self.dualStackPlan())

        #expect(settings.dnsSettings?.servers == ["1.1.1.1", "2606:4700:4700::1111"])
        #expect(settings.dnsSettings?.searchDomains == ["corp.example"])
        #expect(settings.dnsSettings?.matchDomains == [""])
    }

    @Test
    func usesTheFixedMTUWithAPlaceholderRemoteAddress() throws {
        let settings = NetworkSettingsMapper.settings(for: try Self.dualStackPlan())

        #expect(settings.tunnelRemoteAddress == "127.0.0.1")
        #expect(settings.mtu == 1420)
        #expect(settings.tunnelOverheadBytes == nil)
    }

    @Test
    func leavesUnplannedPartsToTheSystem() throws {
        let plan = TunnelNetworkPlan(
            ipv4: TunnelAddressFamilyPlan(
                addresses: [try IPNetwork("10.14.0.2/32")], includedRoutes: [.ipv4DefaultRoute]),
            ipv6: nil,
            dns: nil,
            mtu: .pathMTUWithOverhead(bytes: 80)
        )

        let settings = NetworkSettingsMapper.settings(for: plan)

        #expect(settings.ipv4Settings?.subnetMasks == ["255.255.255.255"])
        #expect(settings.ipv6Settings == nil)
        #expect(settings.dnsSettings == nil)
        #expect(settings.mtu == nil)
        #expect(settings.tunnelOverheadBytes == 80)
    }

    private static func dualStackPlan() throws -> TunnelNetworkPlan {
        TunnelNetworkPlan(
            ipv4: TunnelAddressFamilyPlan(
                addresses: [try IPNetwork("10.14.0.2/16")],
                includedRoutes: [.ipv4DefaultRoute, try IPNetwork("192.168.5.0/24")]
            ),
            ipv6: TunnelAddressFamilyPlan(
                addresses: [try IPNetwork("fd00::2/64")], includedRoutes: [.ipv6DefaultRoute]),
            dns: TunnelDNSPlan(
                servers: [try SharedKernel.IPAddress("1.1.1.1"), try SharedKernel.IPAddress("2606:4700:4700::1111")],
                searchDomains: [try DomainName("corp.example")],
                scope: .allDomains
            ),
            mtu: .fixed(try MTU(1420))
        )
    }
}
