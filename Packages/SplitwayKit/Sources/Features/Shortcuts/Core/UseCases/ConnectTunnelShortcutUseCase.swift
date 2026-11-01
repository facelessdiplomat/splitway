import TunnelConnection
import TunnelLibrary

public struct ConnectTunnelShortcutUseCase: Sendable {
    private let loadTunnels: LoadTunnelsUseCase
    private let activateTunnel: ActivateTunnelUseCase

    public init(loadTunnels: LoadTunnelsUseCase, activateTunnel: ActivateTunnelUseCase) {
        self.loadTunnels = loadTunnels
        self.activateTunnel = activateTunnel
    }

    public func execute(_ identifier: TunnelIdentifier) async throws(TunnelShortcutError) {
        let tunnel = try await readableTunnel(identifiedBy: identifier)
        do {
            try await activateTunnel.execute(tunnel)
        } catch {
            throw .connectionFailed(error)
        }
    }

    private func readableTunnel(identifiedBy identifier: TunnelIdentifier) async throws(TunnelShortcutError) -> Tunnel {
        let snapshot: TunnelLibrarySnapshot
        do {
            snapshot = try await loadTunnels.execute()
        } catch {
            throw .libraryUnavailable
        }
        guard let entry = snapshot.entries.first(where: { entry in entry.id == identifier }) else {
            throw .tunnelNotFound
        }
        guard case .readable(let tunnel) = entry else {
            throw .tunnelUnreadable
        }
        return tunnel
    }
}
