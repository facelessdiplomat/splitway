#if os(macOS)
    import TunnelCoreFramework
    import TunnelEngine

    public struct TunnelCoreUserspaceNetworkEngine: UserspaceNetworkEngine {
        private static let addressSeparator = "\n"

        public init() {}

        public func startNetwork(
            configuration: UAPIConfiguration,
            interface: UserspaceNetworkInterface
        ) throws(TunnelEngineError) -> any RunningUserspaceNetwork {
            let addresses = interface.addresses.map(String.init(describing:)).joined(separator: Self.addressSeparator)
            let dnsServers = interface.dnsServers.map(String.init(describing:)).joined(separator: Self.addressSeparator)
            var handle: Int32 = 0
            let status = configuration.text.withCString { configurationText in
                addresses.withCString { addressesText in
                    dnsServers.withCString { dnsServersText in
                        tc_usernet_start(
                            configurationText, addressesText, dnsServersText, Int32(interface.mtu.value), &handle)
                    }
                }
            }
            try TunnelEngineError.check(status)
            return TunnelCoreUserspaceNetwork(handle: handle)
        }
    }
#endif
