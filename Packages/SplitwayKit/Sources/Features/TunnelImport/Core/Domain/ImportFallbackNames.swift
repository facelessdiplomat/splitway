import TunnelLibrary

public struct ImportFallbackNames: Sendable, Equatable {
    public let pastedText: TunnelName
    public let scannedCode: TunnelName

    public init(pastedText: TunnelName, scannedCode: TunnelName) {
        self.pastedText = pastedText
        self.scannedCode = scannedCode
    }

    func name(for source: ImportSource) -> TunnelName {
        source == .qrCode ? scannedCode : pastedText
    }
}
