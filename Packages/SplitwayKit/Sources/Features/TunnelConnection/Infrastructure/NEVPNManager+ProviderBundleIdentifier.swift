import NetworkExtension

extension NEVPNManager {
    var providerBundleIdentifier: String? {
        (protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier
    }
}
