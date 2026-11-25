import AppRouting
import TunnelLibrary

public struct TunnelLibraryActions: Sendable {
    let loadTunnels: LoadTunnelsUseCase
    let deleteTunnel: DeleteTunnelUseCase
    let duplicateTunnel: DuplicateTunnelUseCase
    let reorderTunnels: ReorderTunnelsUseCase
    let loadServiceNames: @Sendable () async -> [ServiceIdentifier: String]

    public init(
        loadTunnels: LoadTunnelsUseCase,
        deleteTunnel: DeleteTunnelUseCase,
        duplicateTunnel: DuplicateTunnelUseCase,
        reorderTunnels: ReorderTunnelsUseCase,
        loadServiceNames: @escaping @Sendable () async -> [ServiceIdentifier: String] = { [:] }
    ) {
        self.loadTunnels = loadTunnels
        self.deleteTunnel = deleteTunnel
        self.duplicateTunnel = duplicateTunnel
        self.reorderTunnels = reorderTunnels
        self.loadServiceNames = loadServiceNames
    }
}
