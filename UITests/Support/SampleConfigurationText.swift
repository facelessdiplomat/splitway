enum SampleConfigurationText {
    static func make() -> String {
        """
        [Interface]
        PrivateKey = \(RandomKeyText.make())
        Address = 10.20.0.2/32

        [Peer]
        PublicKey = \(RandomKeyText.make())
        AllowedIPs = 0.0.0.0/0
        Endpoint = vpn.example.com:51820
        """
    }
}
