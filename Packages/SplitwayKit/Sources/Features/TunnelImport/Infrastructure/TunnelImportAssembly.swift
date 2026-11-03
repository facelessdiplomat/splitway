import Foundation
import TunnelImport
import TunnelLibrary

public struct TunnelImportAssembly: Sendable {
    private let records: any TunnelRecordRepository
    private let secrets: any TunnelSecretStore

    public init(records: any TunnelRecordRepository, secrets: any TunnelSecretStore) {
        self.records = records
        self.secrets = secrets
    }

    public var confirmImport: ConfirmImportUseCase {
        ConfirmImportUseCase(records: records, secrets: secrets)
    }

    public var fileReader: SecurityScopedFileReader {
        SecurityScopedFileReader()
    }

    public var clipboard: SystemClipboard {
        SystemClipboard()
    }

    public func prepareImport(fallbackName: TunnelName) -> PrepareImportUseCase {
        PrepareImportUseCase(
            records: records,
            secrets: secrets,
            archiveReader: ZIPArchiveReader(),
            fallbackName: fallbackName
        )
    }
}
