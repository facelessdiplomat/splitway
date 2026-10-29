import TunnelLibrary

public struct TunnelLibraryNavigation: Sendable {
    let editTunnel: @MainActor @Sendable (Tunnel) -> Void
    let showLog: @MainActor @Sendable () -> Void

    public init(
        editTunnel: @escaping @MainActor @Sendable (Tunnel) -> Void,
        showLog: @escaping @MainActor @Sendable () -> Void
    ) {
        self.editTunnel = editTunnel
        self.showLog = showLog
    }
}
