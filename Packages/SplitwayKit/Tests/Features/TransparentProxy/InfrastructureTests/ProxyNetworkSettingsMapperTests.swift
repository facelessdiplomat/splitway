#if os(macOS)
    import Network
    import NetworkExtension
    import SharedKernel
    import Testing
    import TransparentProxy
    import TransparentProxyInfrastructure
    import TunnelConfiguration
    import TunnelConfigurationTestSupport

    @Suite
    struct ProxyNetworkSettingsMapperTests {
        private static let endpointAddress = IPAddress.ipv4(0xC633_6401)

        @Test
        func includesTheTunnelNetworksAndExcludesTheEndpointOfTheTunnel() throws {
            let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
            let plan = TransparentProxyNetworkPlan(
                for: configuration, resolvedEndpointAddresses: [Self.endpointAddress])

            let settings = TransparentProxyNetworkSettingsMapper.settings(for: plan)

            let included = Set((settings.includedNetworkRules ?? []).map(Self.description(of:)))
            let excluded = Set((settings.excludedNetworkRules ?? []).map(Self.description(of:)))
            #expect(included.isSuperset(of: ["0.0.0.0/0", "2000::/3"]))
            #expect(excluded.contains("198.51.100.1/32"))
            #expect(included.count == plan.includedNetworks.networks.count)
        }

        private static func description(of rule: NENetworkRule) -> String {
            guard case .hostPort(let host, _) = rule.matchRemoteHostOrNetworkEndpoint else { return "" }
            return "\(host)/\(rule.matchRemotePrefix)"
        }
    }
#endif
