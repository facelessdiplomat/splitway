import NetworkExtension

extension NETunnelProviderManager {
    var providerBundleIdentifier: String? {
        (protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier
    }
}
