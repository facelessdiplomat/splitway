#if os(iOS)
    import DesignSystemPresentation
    import SwiftUI

    struct QRScannerContent: View {
        let model: QRScannerModel
        @Environment(\.openURL) private var openURL

        var body: some View {
            switch model.state {
            case .preparing:
                ProgressView()
            case .scanning:
                QRCodeCameraView { text in
                    model.recognize(text)
                } reportFailure: {
                    model.reportCameraFailure()
                }
                .ignoresSafeArea()
            case .cameraUnavailable:
                EmptyStateView(
                    Text("Camera scanning is unavailable", bundle: .module),
                    systemImage: "camera",
                    message: Text("Choose a photo of the QR code instead.", bundle: .module)
                )
            case .accessDenied:
                accessDeniedView
            case .accessRestricted:
                EmptyStateView(
                    Text("Camera access is restricted", bundle: .module),
                    systemImage: "lock",
                    message: Text(
                        "Camera use is restricted on this device. Choose a photo of the QR code instead.",
                        bundle: .module)
                )
            }
        }

        private var accessDeniedView: some View {
            EmptyStateView(
                Text("No access to the camera", bundle: .module),
                systemImage: "hand.raised",
                message: Text("Allow camera access in Settings to scan QR codes, or choose a photo.", bundle: .module)
            ) {
                if let settings = URL(string: UIApplication.openSettingsURLString) {
                    Button {
                        openURL(settings)
                    } label: {
                        Text("Open Settings", bundle: .module)
                    }
                }
            }
        }
    }
#endif
