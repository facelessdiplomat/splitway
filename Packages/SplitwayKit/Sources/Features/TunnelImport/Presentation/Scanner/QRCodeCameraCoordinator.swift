#if os(iOS)
    import VisionKit

    @MainActor
    final class QRCodeCameraCoordinator: NSObject, DataScannerViewControllerDelegate {
        private let recognize: @MainActor (String) -> Void

        init(recognize: @escaping @MainActor (String) -> Void) {
            self.recognize = recognize
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for case .barcode(let barcode) in addedItems {
                if let text = barcode.payloadStringValue {
                    recognize(text)
                }
            }
        }
    }
#endif
