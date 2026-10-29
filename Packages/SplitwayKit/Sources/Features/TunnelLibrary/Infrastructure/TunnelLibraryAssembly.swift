import Foundation
import TunnelLibrary

public struct TunnelLibraryAssembly: Sendable {
    public let records: FileTunnelRecordRepository
    public let secrets: KeychainTunnelSecretStore

    public init(storageDirectory: URL, keychainAccessGroup: String? = nil) {
        records = FileTunnelRecordRepository(directory: storageDirectory)
        secrets = KeychainTunnelSecretStore(accessGroup: keychainAccessGroup)
    }

    public var loadTunnels: LoadTunnelsUseCase {
        LoadTunnelsUseCase(records: records, secrets: secrets)
    }

    public var createTunnel: CreateTunnelUseCase {
        CreateTunnelUseCase(records: records, secrets: secrets)
    }

    public var updateTunnel: UpdateTunnelUseCase {
        UpdateTunnelUseCase(records: records, secrets: secrets)
    }

    public var renameTunnel: RenameTunnelUseCase {
        RenameTunnelUseCase(records: records)
    }

    public var exportTunnels: ExportTunnelsUseCase {
        ExportTunnelsUseCase(records: records, secrets: secrets, archiveWriter: ZIPArchiveWriter())
    }

    public var duplicateTunnel: DuplicateTunnelUseCase {
        DuplicateTunnelUseCase(records: records, secrets: secrets)
    }

    public var reorderTunnels: ReorderTunnelsUseCase {
        ReorderTunnelsUseCase(records: records)
    }

    public func deleteTunnel(stoppingActiveTunnelWith activityProbe: any TunnelActivityProbe) -> DeleteTunnelUseCase {
        DeleteTunnelUseCase(records: records, secrets: secrets, activityProbe: activityProbe)
    }
}
