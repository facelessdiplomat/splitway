import Foundation
import SharedKernel
import SharedKernelTestSupport
import TunnelConfiguration

public struct RandomTunnelConfigurationGenerator {
    private static let keyByteCount = 32
    private static let maximumListLength = 3
    private static let searchDomainPool = ["corp.example", "lan", "vpn.example.net", "home.arpa"]
    private static let hostNamePool = ["vpn.example.com", "edge-01.example.net", "gateway.home.arpa"]

    private var generator: SeededRandomNumberGenerator

    public init(seed: UInt64) {
        generator = SeededRandomNumberGenerator(seed: seed)
    }

    public mutating func configuration() throws -> TunnelConfiguration {
        let privateKey = try PrivateKey(base64Encoded: randomKeyText())
        let addresses = try randomNetworks(minimumCount: 1)
        let listenPort = coinFlip() ? try NetworkPort(randomInteger(in: NetworkPort.validRange)) : nil
        let mtu = coinFlip() ? try MTU(randomInteger(in: MTU.supportedRange)) : nil
        let servers = (0..<randomCount()).map { _ in randomAddress() }
        let searchDomains = try (0..<randomCount()).map { _ in try DomainName(randomElement(of: Self.searchDomainPool))
        }
        let interface = InterfaceConfiguration(
            privateKey: privateKey,
            addresses: addresses,
            listenPort: listenPort,
            mtu: mtu,
            dns: DNSConfiguration(servers: servers, searchDomains: searchDomains)
        )
        return try TunnelConfiguration(interface: interface, peers: randomPeers())
    }

    private mutating func randomPeers() throws -> [PeerConfiguration] {
        var usedKeys: Set<String> = []
        var peers: [PeerConfiguration] = []
        for _ in 0..<randomCount() {
            let keyText = randomKeyText()
            guard usedKeys.insert(keyText).inserted else { continue }
            peers.append(try randomPeer(publicKeyText: keyText))
        }
        return peers
    }

    private mutating func randomPeer(publicKeyText: String) throws -> PeerConfiguration {
        let publicKey = try PublicKey(base64Encoded: publicKeyText)
        let presharedKey = coinFlip() ? try PresharedKey(base64Encoded: randomKeyText()) : nil
        let allowedIPs = AllowedIPs(try randomNetworks(minimumCount: 0))
        let endpoint = coinFlip() ? try randomEndpoint() : nil
        let persistentKeepalive =
            coinFlip()
            ? try PersistentKeepalive(seconds: randomInteger(in: PersistentKeepalive.validIntervalRange)) : nil
        return PeerConfiguration(
            publicKey: publicKey,
            presharedKey: presharedKey,
            allowedIPs: allowedIPs,
            endpoint: endpoint,
            persistentKeepalive: persistentKeepalive
        )
    }

    private mutating func randomEndpoint() throws -> Endpoint {
        let port = try NetworkPort(randomInteger(in: NetworkPort.validRange))
        guard coinFlip() else {
            return Endpoint(host: .name(try DomainName(randomElement(of: Self.hostNamePool))), port: port)
        }
        return Endpoint(host: .address(randomAddress()), port: port)
    }

    private mutating func randomNetworks(minimumCount: Int) throws -> [IPNetwork] {
        try (0..<randomInteger(in: minimumCount...Self.maximumListLength)).map { _ in
            let address = randomAddress()
            return try IPNetwork(address: address, prefixLength: randomInteger(in: 0...address.family.bitWidth))
        }
    }

    private mutating func randomAddress() -> IPAddress {
        guard coinFlip() else {
            return .ipv6(UInt128.random(in: 0...UInt128.max, using: &generator))
        }
        return .ipv4(UInt32.random(in: 0...UInt32.max, using: &generator))
    }

    private mutating func randomKeyText() -> String {
        Data((0..<Self.keyByteCount).map { _ in UInt8.random(in: 0...UInt8.max, using: &generator) })
            .base64EncodedString()
    }

    private mutating func randomCount() -> Int {
        randomInteger(in: 0...Self.maximumListLength)
    }

    private mutating func randomInteger(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &generator)
    }

    private mutating func randomElement(of pool: [String]) -> String {
        pool[Int.random(in: pool.indices, using: &generator)]
    }

    private mutating func coinFlip() -> Bool {
        Bool.random(using: &generator)
    }
}
