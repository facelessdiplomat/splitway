import TunnelLibrary

public struct TunnelDeletionRequest: Sendable, Hashable {
    public let tunnelID: TunnelIdentifier
    public let tunnelName: String
    public let disconnectsTunnel: Bool

    public init(tunnelID: TunnelIdentifier, tunnelName: String, disconnectsTunnel: Bool) {
        self.tunnelID = tunnelID
        self.tunnelName = tunnelName
        self.disconnectsTunnel = disconnectsTunnel
    }
}
