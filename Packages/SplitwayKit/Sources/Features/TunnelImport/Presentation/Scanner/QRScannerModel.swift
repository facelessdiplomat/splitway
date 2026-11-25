import Foundation
import Observation
import TunnelImport

@MainActor
@Observable
public final class QRScannerModel: Identifiable {
    public private(set) var state = QRScannerState.preparing
    public private(set) var photoProblem: QRPhotoProblem?
    private var hasRecognizedCode = false

    private let cameraAccess: any CameraAccess
    private let decoder: any QRCodeDecoder
    private let didRecognize: @MainActor ([String]) -> Void

    public init(
        cameraAccess: any CameraAccess,
        decoder: any QRCodeDecoder,
        didRecognize: @escaping @MainActor ([String]) -> Void
    ) {
        self.cameraAccess = cameraAccess
        self.decoder = decoder
        self.didRecognize = didRecognize
    }

    public func prepare(isCameraScanningSupported: Bool) async {
        guard isCameraScanningSupported else {
            state = .cameraUnavailable
            return
        }
        switch cameraAccess.authorization() {
        case .authorized:
            state = .scanning
        case .notDetermined:
            state = await cameraAccess.requestAccess() ? .scanning : .accessDenied
        case .denied:
            state = .accessDenied
        case .restricted:
            state = .accessRestricted
        }
    }

    public func recognize(_ text: String) {
        finish(with: [text])
    }

    public func reportCameraFailure() {
        state = .cameraUnavailable
    }

    public func importPhoto(_ imageData: Data?) async {
        guard let imageData else {
            photoProblem = .unreadableImage
            return
        }
        do {
            let texts = try await decoder.decodeTexts(in: imageData)
            if texts.isEmpty {
                photoProblem = .noQRCode
            } else {
                finish(with: texts)
            }
        } catch {
            photoProblem = .unreadableImage
        }
    }

    public func dismissPhotoProblem() {
        photoProblem = nil
    }

    private func finish(with texts: [String]) {
        guard !hasRecognizedCode else { return }
        hasRecognizedCode = true
        didRecognize(texts)
    }
}
