#if os(iOS)
    import SwiftUI
    import VisionKit

    struct QRCodeCameraView: UIViewControllerRepresentable {
        let recognize: @MainActor (String) -> Void
        let reportFailure: @MainActor () -> Void

        func makeUIViewController(context: Context) -> DataScannerViewController {
            let scanner = DataScannerViewController(
                recognizedDataTypes: [.barcode(symbologies: [.qr])],
                qualityLevel: .balanced,
                recognizesMultipleItems: false,
                isHighFrameRateTrackingEnabled: false,
                isPinchToZoomEnabled: true,
                isGuidanceEnabled: true,
                isHighlightingEnabled: true
            )
            scanner.delegate = context.coordinator
            return scanner
        }

        func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
            guard !scanner.isScanning else { return }
            do {
                try scanner.startScanning()
            } catch {
                Task { reportFailure() }
            }
        }

        static func dismantleUIViewController(
            _ scanner: DataScannerViewController, coordinator: QRCodeCameraCoordinator
        ) {
            scanner.stopScanning()
        }

        func makeCoordinator() -> QRCodeCameraCoordinator {
            QRCodeCameraCoordinator(recognize: recognize)
        }
    }
#endif
