public struct PeerConfiguration: Sendable, Hashable {
    public let publicKey: PublicKey
    public let presharedKey: PresharedKey?
    public let allowedIPs: AllowedIPs
    public let endpoint: Endpoint?
    public let persistentKeepalive: PersistentKeepalive?

    public init(
        publicKey: PublicKey,
        presharedKey: PresharedKey? = nil,
        allowedIPs: AllowedIPs = AllowedIPs([]),
        endpoint: Endpoint? = nil,
        persistentKeepalive: PersistentKeepalive? = nil
    ) {
        self.publicKey = publicKey
        self.presharedKey = presharedKey
        self.allowedIPs = allowedIPs
        self.endpoint = endpoint
        self.persistentKeepalive = persistentKeepalive
    }
}
