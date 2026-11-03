import TunnelLibrary

public struct TunnelLibraryActions: Sendable {
    let loadTunnels: LoadTunnelsUseCase
    let deleteTunnel: DeleteTunnelUseCase
    let duplicateTunnel: DuplicateTunnelUseCase
    let reorderTunnels: ReorderTunnelsUseCase

    public init(
        loadTunnels: LoadTunnelsUseCase,
        deleteTunnel: DeleteTunnelUseCase,
        duplicateTunnel: DuplicateTunnelUseCase,
        reorderTunnels: ReorderTunnelsUseCase
    ) {
        self.loadTunnels = loadTunnels
        self.deleteTunnel = deleteTunnel
        self.duplicateTunnel = duplicateTunnel
        self.reorderTunnels = reorderTunnels
    }
}
