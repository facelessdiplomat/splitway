#if os(macOS)
    import Network
    import NetworkExtension
    import SharedKernel
    import TransparentProxy

    public enum TransparentProxyNetworkSettingsMapper {
        private static let tunnelRemoteAddress = "127.0.0.1"
        private static let anyPort: NWEndpoint.Port = 0

        public static func settings(for plan: TransparentProxyNetworkPlan) -> NETransparentProxyNetworkSettings {
            let settings = NETransparentProxyNetworkSettings(tunnelRemoteAddress: tunnelRemoteAddress)
            settings.includedNetworkRules = rules(for: plan.includedNetworks)
            settings.excludedNetworkRules = rules(for: plan.excludedNetworks)
            return settings
        }

        private static func rules(for networks: IPNetworkSet) -> [NENetworkRule] {
            networks.networks.map { network in
                NENetworkRule(
                    destinationNetworkEndpoint: .hostPort(
                        host: NWEndpoint.Host(network.address.description), port: anyPort),
                    prefix: network.prefixLength,
                    protocol: .any
                )
            }
        }
    }
#endif
