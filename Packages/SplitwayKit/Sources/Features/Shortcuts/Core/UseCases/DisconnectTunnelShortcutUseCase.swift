import TunnelLibrary

public struct DisconnectTunnelShortcutUseCase: Sendable {
    private let activityProbe: any TunnelActivityProbe

    public init(activityProbe: any TunnelActivityProbe) {
        self.activityProbe = activityProbe
    }

    public func execute(_ identifier: TunnelIdentifier) async throws(TunnelShortcutError) {
        guard await activityProbe.isActive(identifier) else { return }
        do {
            try await activityProbe.stop(identifier)
        } catch {
            throw .disconnectionFailed
        }
    }
}
