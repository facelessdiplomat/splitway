import Foundation
import TunnelLibrary

public struct TunnelLibraryAssembly: Sendable {
    private let records: FileTunnelRecordRepository
    private let secrets: KeychainTunnelSecretStore

    public init(storageDirectory: URL, keychainAccessGroup: String? = nil) {
        records = FileTunnelRecordRepository(directory: storageDirectory)
        secrets = KeychainTunnelSecretStore(accessGroup: keychainAccessGroup)
    }

    public var loadTunnels: LoadTunnelsUseCase {
        LoadTunnelsUseCase(records: records, secrets: secrets)
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
