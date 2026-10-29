public struct RelayPolicy: Sendable, Hashable {
    public static let standard = RelayPolicy(tcp: .standard, udp: .standard)

    public let tcp: TCPRelayPolicy
    public let udp: UDPRelayPolicy

    public init(tcp: TCPRelayPolicy, udp: UDPRelayPolicy) {
        self.tcp = tcp
        self.udp = udp
    }
}
