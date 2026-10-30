#if os(macOS)
    import Network
    import NetworkExtension
    import SharedKernel
    import TransparentProxy

    public enum TransparentProxyNetworkSettingsMapper {
        private static let tunnelRemoteAddress = "127.0.0.1"
        private static let anyPort: NWEndpoint.Port = 0
        private static let dnsPort: NWEndpoint.Port = 53
        private static let unspecifiedHosts: [NWEndpoint.Host] = ["0.0.0.0", "::"]

        public static func settings(for plan: TransparentProxyNetworkPlan) -> NETransparentProxyNetworkSettings {
            let settings = NETransparentProxyNetworkSettings(tunnelRemoteAddress: tunnelRemoteAddress)
            settings.includedNetworkRules = includedRules(for: plan)
            settings.excludedNetworkRules = plan.excludedNetworks.networks
                .filter { network in !network.address.isUnspecified }
                .map(rule(for:))
            return settings
        }

        private static func includedRules(for plan: TransparentProxyNetworkPlan) -> [NENetworkRule] {
            let networks = plan.includedNetworks.networks
            guard !networks.contains(where: { network in network.address.isUnspecified }) else {
                return [everyRemoteNetworkRule]
            }
            let dnsRules = plan.dnsRedirection.redirectsQueries ? dnsQueryRules : []
            return networks.map(rule(for:)) + dnsRules
        }

        private static var dnsQueryRules: [NENetworkRule] {
            unspecifiedHosts.map { host in
                NENetworkRule(
                    destinationNetworkEndpoint: .hostPort(host: host, port: dnsPort), prefix: 0, protocol: .any)
            }
        }

        private static var everyRemoteNetworkRule: NENetworkRule {
            NENetworkRule(
                remoteNetworkEndpoint: nil,
                remotePrefix: 0,
                localNetworkEndpoint: nil,
                localPrefix: 0,
                protocol: .any,
                direction: .outbound
            )
        }

        private static func rule(for network: IPNetwork) -> NENetworkRule {
            NENetworkRule(
                destinationNetworkEndpoint: .hostPort(
                    host: NWEndpoint.Host(network.address.description), port: anyPort),
                prefix: network.prefixLength,
                protocol: .any
            )
        }
    }
#endif
