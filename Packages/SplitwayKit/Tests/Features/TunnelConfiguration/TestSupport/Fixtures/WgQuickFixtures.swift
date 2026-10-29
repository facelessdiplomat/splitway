import Foundation

public enum WgQuickFixtures {
    public static let minimal = """
        [Interface]
        PrivateKey = \(SampleKeys.interfacePrivateKeyText)
        Address = 10.14.0.2/16

        [Peer]
        PublicKey = \(SampleKeys.firstPeerPublicKeyText)
        AllowedIPs = 0.0.0.0/0
        Endpoint = vpn.example.com:51820
        """

    public static let full = """
        [Interface]
        PrivateKey = \(SampleKeys.interfacePrivateKeyText)
        Address = 10.14.0.2/16, fd00::2/64
        ListenPort = 51820
        MTU = 1420
        DNS = 1.1.1.1, 2606:4700:4700::1111, corp.example

        [Peer]
        PublicKey = \(SampleKeys.firstPeerPublicKeyText)
        PresharedKey = \(SampleKeys.presharedKeyText)
        AllowedIPs = 0.0.0.0/0, ::/0
        Endpoint = [2001:db8::1]:51820
        PersistentKeepalive = 25
        """

    public static let multiplePeers = """
        [Interface]
        PrivateKey = \(SampleKeys.interfacePrivateKeyText)
        Address = 10.0.0.2/32

        [Peer]
        PublicKey = \(SampleKeys.firstPeerPublicKeyText)
        AllowedIPs = 10.0.0.0/24
        Endpoint = 203.0.113.10:51820

        [Peer]
        PublicKey = \(SampleKeys.secondPeerPublicKeyText)
        AllowedIPs = 10.1.0.0/24
        Endpoint = 203.0.113.20:51820
        """

    public static let commercialProviderStyle = """
        #
        # Use this configuration with WireGuard client
        #
        [Interface]
        Address = 10.14.0.2/16
        PrivateKey = \(SampleKeys.interfacePrivateKeyText)
        DNS = 192.0.2.53, 198.51.100.53
        [Peer]
        PublicKey = \(SampleKeys.firstPeerPublicKeyText)
        AllowedIPs = 0.0.0.0/0
        Endpoint = vpn-01.prod.example.net:51820
        """

    public static let mixedCaseWithTrailingComments = """
        [INTERFACE]
        privatekey = \(SampleKeys.interfacePrivateKeyText)
        ADDRESS = 10.14.0.2/16 # home network

        [peer]
        PublicKey=\(SampleKeys.firstPeerPublicKeyText)
        allowedips = 10.0.0.0/8 # office
        AllowedIPs = 192.168.0.0/16
        """

    public static let windowsLineEndingsWithByteOrderMark =
        "\u{FEFF}" + minimal.replacingOccurrences(of: "\n", with: "\r\n")

    public static let wgQuickHooks = """
        [Interface]
        PrivateKey = \(SampleKeys.interfacePrivateKeyText)
        Address = 10.14.0.2/16
        PostUp = iptables -A FORWARD -i %i -j ACCEPT
        PreDown = echo down
        Table = off
        SaveConfig = true

        [Peer]
        PublicKey = \(SampleKeys.firstPeerPublicKeyText)
        AllowedIPs = 0.0.0.0/0
        """

    public static let amneziaWG = """
        [Interface]
        PrivateKey = \(SampleKeys.interfacePrivateKeyText)
        Address = 10.14.0.2/16
        Jc = 4
        Jmin = 40
        H1 = 1234567891

        [Peer]
        PublicKey = \(SampleKeys.firstPeerPublicKeyText)
        AllowedIPs = 0.0.0.0/0
        """
}
