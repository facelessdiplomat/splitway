#if os(iOS)
    import SwiftUI

    struct QRScannerPresenter: ViewModifier {
        @Bindable var model: TunnelImportModel

        func body(content: Content) -> some View {
            content.sheet(item: $model.qrScanner, onDismiss: previewScannedCodes) { scanner in
                NavigationStack {
                    QRScannerView(model: scanner) {
                        model.qrScanner = nil
                    }
                }
            }
        }

        private func previewScannedCodes() {
            Task.immediate { await model.previewScannedCodes() }
        }
    }
#endif
