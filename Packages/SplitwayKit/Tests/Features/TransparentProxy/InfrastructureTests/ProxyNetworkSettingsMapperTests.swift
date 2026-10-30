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
        func includesEveryRemoteNetworkForATunnelOfAllAddresses() throws {
            let settings = try Self.settings(for: WgQuickFixtures.minimal)

            let included = try #require(settings.includedNetworkRules)
            #expect(included.count == 1)
            #expect(included.first?.matchRemoteHostOrNetworkEndpoint == nil)
            #expect(included.first?.matchLocalNetworkEndpoint == nil)
            #expect(included.first?.matchDirection == .outbound)
            #expect(included.first?.matchProtocol == .any)
        }

        @Test
        func includesTheNetworksOfATunnelOfSomeNetworks() throws {
            let settings = try Self.settings(for: WgQuickFixtures.multiplePeers)

            let included = (settings.includedNetworkRules ?? []).map(Self.description(of:))
            #expect(Set(included) == ["10.0.0.0/24", "10.1.0.0/24"])
        }

        @Test
        func takesDNSQueriesToEveryResolverWhenTheTunnelRedirectsThem() throws {
            let partialTunnel = WgQuickFixtures.commercialProviderStyle.replacingOccurrences(
                of: "AllowedIPs = 0.0.0.0/0", with: "AllowedIPs = 192.0.2.0/24")

            let settings = try Self.settings(for: partialTunnel)

            let rules = settings.includedNetworkRules ?? []
            #expect(Set(rules.compactMap(Self.dnsQueryHost(of:))) == ["0.0.0.0", "::"])
            #expect(rules.map(Self.description(of:)).contains("192.0.2.0/24"))
        }

        @Test
        func leavesDNSQueriesOutWhenNothingRedirectsThem() throws {
            let settings = try Self.settings(for: WgQuickFixtures.multiplePeers)

            #expect((settings.includedNetworkRules ?? []).compactMap(Self.dnsQueryHost(of:)).isEmpty)
        }

        @Test
        func excludesTheEndpointOfTheTunnel() throws {
            let settings = try Self.settings(for: WgQuickFixtures.minimal)

            let excluded = (settings.excludedNetworkRules ?? []).map(Self.description(of:))
            #expect(excluded.contains("198.51.100.1/32"))
            #expect(!excluded.contains(""))
        }

        @Test
        func leavesAnUnspecifiedEndpointAddressOutOfTheExcludedRules() throws {
            let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
            let plan = TransparentProxyNetworkPlan(for: configuration, resolvedEndpointAddresses: [.ipv4(0)])

            let settings = TransparentProxyNetworkSettingsMapper.settings(for: plan)

            let excluded = (settings.excludedNetworkRules ?? []).map(Self.description(of:))
            #expect(!excluded.contains("0.0.0.0/32"))
        }

        private static func settings(for text: String) throws -> NETransparentProxyNetworkSettings {
            let configuration = try #require(WgQuickConfigurationParser.parse(text).configuration)
            let plan = TransparentProxyNetworkPlan(for: configuration, resolvedEndpointAddresses: [endpointAddress])
            return TransparentProxyNetworkSettingsMapper.settings(for: plan)
        }

        private static func dnsQueryHost(of rule: NENetworkRule) -> String? {
            guard case .hostPort(let host, let port) = rule.matchRemoteHostOrNetworkEndpoint, port == 53 else {
                return nil
            }
            return "\(host)"
        }

        private static func description(of rule: NENetworkRule) -> String {
            guard case .hostPort(let host, _) = rule.matchRemoteHostOrNetworkEndpoint else { return "" }
            return "\(host)/\(rule.matchRemotePrefix)"
        }
    }
#endif
