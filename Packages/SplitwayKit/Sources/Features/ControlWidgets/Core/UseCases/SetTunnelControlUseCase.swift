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

    public func execute(isOn: Bool, selection: TunnelIdentifier?) async throws(TunnelControlError) {
        let snapshot: TunnelControlSnapshot
        do {
            snapshot = try await read.execute(selection: selection)
        } catch {
            throw .action(error)
        }
        guard let target = snapshot.targetTunnel else { throw .action(.tunnelNotFound) }
        guard isOn else {
            try await performing { () throws(TunnelShortcutError) in try await disconnect.execute(target) }
            return
        }
        guard snapshot.slot.tunnelID != nil else { throw .vpnConfigurationMissing }
        try await performing { () throws(TunnelShortcutError) in try await connect.execute(target) }
    }

    private func performing(
        _ action: () async throws(TunnelShortcutError) -> Void
    ) async throws(TunnelControlError) {
        do {
            try await action()
        } catch {
            throw .action(error)
        }
    }
}
