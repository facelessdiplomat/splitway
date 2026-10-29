import Foundation
import Testing
import TunnelImport
import TunnelImportPresentation

@MainActor
@Suite
final class QRScannerModelTests {
    struct AccessOutcome: Sendable {
        let authorization: CameraAuthorization
        let grantsAccess: Bool
        let state: QRScannerState
    }

    private static let photo = Data("photo".utf8)

    private var recognizedBatches: [[String]] = []

    @Test(arguments: [
        AccessOutcome(authorization: .authorized, grantsAccess: false, state: .scanning),
        AccessOutcome(authorization: .notDetermined, grantsAccess: true, state: .scanning),
        AccessOutcome(authorization: .notDetermined, grantsAccess: false, state: .accessDenied),
        AccessOutcome(authorization: .denied, grantsAccess: true, state: .accessDenied),
        AccessOutcome(authorization: .restricted, grantsAccess: true, state: .accessRestricted),
    ])
    func scansOnlyWithCameraAccess(outcome: AccessOutcome) async {
        let model = scanner(camera: FakeCameraAccess(outcome.authorization, grantsAccess: outcome.grantsAccess))
        #expect(model.state == .preparing)

        await model.prepare(isCameraScanningSupported: true)

        #expect(model.state == outcome.state)
    }

    @Test
    func offersPhotosWhenTheDeviceCannotScan() async {
        let model = scanner(camera: FakeCameraAccess(.authorized))

        await model.prepare(isCameraScanningSupported: false)

        #expect(model.state == .cameraUnavailable)
    }

    @Test
    func offersPhotosWhenTheCameraStopsWorking() async {
        let model = scanner(camera: FakeCameraAccess(.authorized))
        await model.prepare(isCameraScanningSupported: true)

        model.reportCameraFailure()

        #expect(model.state == .cameraUnavailable)
    }

    @Test
    func importsARecognizedCodeOnlyOnce() async {
        let model = scanner(camera: FakeCameraAccess(.authorized))
        await model.prepare(isCameraScanningSupported: true)

        model.recognize("[Interface]")
        model.recognize("[Interface]")

        #expect(recognizedBatches == [["[Interface]"]])
    }

    @Test
    func importsEveryCodeOfAPhoto() async {
        let model = scanner(decoder: StubQRCodeDecoder(.success(["first", "second"])))

        await model.importPhoto(Self.photo)

        #expect(recognizedBatches == [["first", "second"]])
        #expect(model.photoProblem == nil)
    }

    @Test
    func explainsAPhotoWithoutQRCodes() async {
        let model = scanner(decoder: StubQRCodeDecoder(.success([])))

        await model.importPhoto(Self.photo)

        #expect(recognizedBatches.isEmpty)
        #expect(model.photoProblem == .noQRCode)
        model.dismissPhotoProblem()
        #expect(model.photoProblem == nil)
    }

    @Test
    func explainsAPhotoThatCannotBeRead() async {
        let undecodable = scanner(decoder: StubQRCodeDecoder(.failure(.unreadableImage)))
        let unloaded = scanner(decoder: StubQRCodeDecoder(.success(["never"])))

        await undecodable.importPhoto(Self.photo)
        await unloaded.importPhoto(nil)

        #expect(undecodable.photoProblem == .unreadableImage)
        #expect(unloaded.photoProblem == .unreadableImage)
        #expect(recognizedBatches.isEmpty)
    }

    private func scanner(
        camera: FakeCameraAccess = FakeCameraAccess(.authorized),
        decoder: StubQRCodeDecoder = StubQRCodeDecoder()
    ) -> QRScannerModel {
        QRScannerModel(cameraAccess: camera, decoder: decoder) { [weak self] texts in
            self?.recognizedBatches.append(texts)
        }
    }
}
