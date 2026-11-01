public struct TunnelControlValue: Sendable, Hashable {
    public let isOn: Bool
    public let tunnelName: String?

    public init(isOn: Bool, tunnelName: String?) {
        self.isOn = isOn
        self.tunnelName = tunnelName
    }
}
