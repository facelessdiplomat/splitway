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
        #if os(iOS)
            SecurityScopedFileReader(inbox: ReceivedFileInbox(applicationContainer: URL(filePath: NSHomeDirectory())))
        #else
            SecurityScopedFileReader()
        #endif
    }

    public var clipboard: SystemClipboard {
        SystemClipboard()
    }

    public var cameraAccess: SystemCameraAccess {
        SystemCameraAccess()
    }

    public var qrCodeDecoder: VisionQRCodeDecoder {
        VisionQRCodeDecoder()
    }

    public func prepareImport(fallbackNames: ImportFallbackNames) -> PrepareImportUseCase {
        PrepareImportUseCase(
            records: records,
            secrets: secrets,
            archiveReader: ZIPArchiveReader(),
            fallbackNames: fallbackNames
        )
    }
}
