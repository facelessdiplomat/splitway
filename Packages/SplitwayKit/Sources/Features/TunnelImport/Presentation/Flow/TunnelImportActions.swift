import TunnelImport

public struct TunnelImportActions: Sendable {
    let prepareImport: PrepareImportUseCase
    let confirmImport: ConfirmImportUseCase
    let fileReader: any ImportFileReader
    let clipboard: any ClipboardTextSource
    let cameraAccess: any CameraAccess
    let qrCodeDecoder: any QRCodeDecoder

    public init(
        prepareImport: PrepareImportUseCase,
        confirmImport: ConfirmImportUseCase,
        fileReader: any ImportFileReader,
        clipboard: any ClipboardTextSource,
        cameraAccess: any CameraAccess,
        qrCodeDecoder: any QRCodeDecoder
    ) {
        self.prepareImport = prepareImport
        self.confirmImport = confirmImport
        self.fileReader = fileReader
        self.clipboard = clipboard
        self.cameraAccess = cameraAccess
        self.qrCodeDecoder = qrCodeDecoder
    }
}
