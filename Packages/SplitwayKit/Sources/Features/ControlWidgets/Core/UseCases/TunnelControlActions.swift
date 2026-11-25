public struct TunnelControlActions: Sendable {
    public let read: ReadTunnelControlUseCase
    public let set: SetTunnelControlUseCase

    public init(read: ReadTunnelControlUseCase, set: SetTunnelControlUseCase) {
        self.read = read
        self.set = set
    }
}
