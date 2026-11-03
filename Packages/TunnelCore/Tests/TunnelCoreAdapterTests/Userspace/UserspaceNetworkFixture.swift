import SharedKernel
import Testing
import TunnelConfiguration
import TunnelCoreAdapter
import TunnelEngine

struct UserspaceNetworkFixture {
    static let serverAddress = IPAddress.ipv4(0x0A00_0002)
    static let clientAddress = IPAddress.ipv4(0x0A00_0001)
    static let loopbackAddress = IPAddress.ipv4(0x7F00_0001)
    static let echoPort = 7
    static let closedPort = 19
    static let hostname = "echo.tunnel.test"
    static let dialTimeout = Duration.seconds(20)
    static let readByteCount = 64 * 1024
    static let generousCredit = 1 << 20

    let peer: TestPeerProcess
    let network: any RunningUserspaceNetwork

    static func start() async throws -> UserspaceNetworkFixture {
        let clientKey = PrivateKey.generate()
        let peer = try TestPeerProcess(clientPublicKey: clientKey.publicKey)
        let text = """
            [Interface]
            PrivateKey = \(clientKey.base64EncodedText)
            Address = \(clientAddress)/32

            [Peer]
            PublicKey = \(peer.announcement.publicKey)
            AllowedIPs = \(serverAddress)/32
            """
        let configuration = try #require(WgQuickConfigurationParser.parse(text).configuration)
        let serverEndpoint = ResolvedEndpoint(
            address: loopbackAddress,
            port: try NetworkPort(peer.announcement.listenPort)
        )
        let uapi = UAPIConfigurationEncoder.encode(
            configuration,
            resolvedEndpoints: [try #require(configuration.peers.first).publicKey: serverEndpoint]
        )
        let interface = UserspaceNetworkInterface(
            addresses: [clientAddress],
            dnsServers: [serverAddress],
            mtu: try MTU(1_420)
        )
        let network = try TunnelCoreUserspaceNetworkEngine().startNetwork(configuration: uapi, interface: interface)
        return UserspaceNetworkFixture(peer: peer, network: network)
    }

    func destination(port: Int) throws -> UserspaceNetworkDestination {
        UserspaceNetworkDestination(address: Self.serverAddress, port: try NetworkPort(port))
    }

    func dialTCP(port: Int) async throws -> any UserspaceConnection {
        let destination = try destination(port: port)
        let network = network
        return try await BlockingCall.perform { () throws(UserspaceNetworkError) in
            try network.dialTCP(to: destination, timeout: Self.dialTimeout)
        }
    }

    func receiving(_ connection: any UserspaceConnection) throws -> RecordingConnectionReceiver {
        let receiver = RecordingConnectionReceiver()
        try connection.startReceiving(
            into: receiver, readByteCount: Self.readByteCount, initialCredit: Self.generousCredit)
        return receiver
    }

    func write(_ message: [UInt8], to connection: any UserspaceConnection) async throws -> Int {
        try await BlockingCall.perform { () throws(UserspaceNetworkError) in
            let written = message.withUnsafeBytes { bytes in
                Result { () throws(UserspaceNetworkError) in try connection.write(bytes) }
            }
            return try written.get()
        }
    }

    func stop() {
        network.stop()
        peer.stop()
    }
}
