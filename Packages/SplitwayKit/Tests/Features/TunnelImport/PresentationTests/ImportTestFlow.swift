import Foundation
import Testing
import TunnelImport
import TunnelImportPresentation
import TunnelLibrary
import TunnelLibraryTestSupport

@MainActor
final class ImportTestFlow {
    static let pastedName = "Pasted tunnel"
    static let scannedName = "Scanned tunnel"

    let records = InMemoryTunnelRecordRepository()
    let secrets = InMemoryTunnelSecretStore()
    private(set) var importCount = 0

    func model(
        files: ImportFileBatch = ImportFileBatch(payloads: [], unreadableFileNames: []),
        clipboard: String? = nil
    ) throws -> TunnelImportModel {
        TunnelImportModel(
            actions: TunnelImportActions(
                prepareImport: PrepareImportUseCase(
                    records: records,
                    secrets: secrets,
                    archiveReader: RejectingArchiveReader(),
                    fallbackNames: ImportFallbackNames(
                        pastedText: try TunnelName(Self.pastedName),
                        scannedCode: try TunnelName(Self.scannedName)
                    )
                ),
                confirmImport: ConfirmImportUseCase(records: records, secrets: secrets),
                fileReader: FakeImportFileReader(batch: files),
                clipboard: FakeClipboard(contents: clipboard),
                cameraAccess: FakeCameraAccess(.authorized),
                qrCodeDecoder: StubQRCodeDecoder()
            )
        ) { [weak self] in
            self?.importCount += 1
        }
    }

    func preview(of payloads: [ImportPayload]) async throws -> ImportPreviewModel {
        let model = try model()
        await model.importDropped(payloads)
        return try #require(model.preview)
    }

    func storedNames() async throws -> [String] {
        try await records.loadRecords().map(\.name.description)
    }
}
