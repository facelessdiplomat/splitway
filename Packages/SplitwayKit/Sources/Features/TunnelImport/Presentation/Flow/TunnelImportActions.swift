import TunnelImport

public struct TunnelImportActions: Sendable {
    let prepareImport: PrepareImportUseCase
    let confirmImport: ConfirmImportUseCase
    let fileReader: any ImportFileReader
    let clipboard: any ClipboardTextSource

    public init(
        prepareImport: PrepareImportUseCase,
        confirmImport: ConfirmImportUseCase,
        fileReader: any ImportFileReader,
        clipboard: any ClipboardTextSource
    ) {
        self.prepareImport = prepareImport
        self.confirmImport = confirmImport
        self.fileReader = fileReader
        self.clipboard = clipboard
    }
}
