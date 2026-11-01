import Shortcuts
import TunnelLibrary

public struct SetTunnelControlUseCase: Sendable {
    private let read: ReadTunnelControlUseCase
    private let connect: ConnectTunnelShortcutUseCase
    private let disconnect: DisconnectTunnelShortcutUseCase

    public init(
        read: ReadTunnelControlUseCase,
        connect: ConnectTunnelShortcutUseCase,
        disconnect: DisconnectTunnelShortcutUseCase
    ) {
        self.read = read
        self.connect = connect
        self.disconnect = disconnect
    }

    public func execute(isOn: Bool, selection: TunnelIdentifier?) async throws(TunnelShortcutError) {
        guard let target = try await read.execute(selection: selection).targetTunnel else {
            throw .tunnelNotFound
        }
        if isOn {
            try await connect.execute(target)
        } else {
            try await disconnect.execute(target)
        }
    }
}
