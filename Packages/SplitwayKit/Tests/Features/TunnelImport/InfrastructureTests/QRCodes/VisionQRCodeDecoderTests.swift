import Foundation
import Testing
import TunnelImport
import TunnelImportInfrastructure

@Suite
struct VisionQRCodeDecoderTests {
    private static let officeConfiguration = """
        [Interface]
        Address = 10.0.0.2/32

        [Peer]
        Endpoint = office.example.com:51820
        """
    private static let pragueConfiguration = """
        [Interface]
        Address = 10.0.0.3/32

        [Peer]
        Endpoint = prague.example.com:51820
        """

    private let decoder = VisionQRCodeDecoder()

    @Test
    func readsTheTextOfASingleQRCode() async throws {
        let image = try QRCodeImageFixture.pngImage(showing: [Self.officeConfiguration])

        #expect(try await decoder.decodeTexts(in: image) == [Self.officeConfiguration])
    }

    @Test
    func readsEveryQRCodeOfAnImage() async throws {
        let image = try QRCodeImageFixture.pngImage(showing: [Self.officeConfiguration, Self.pragueConfiguration])

        let texts = try await decoder.decodeTexts(in: image)

        #expect(texts.count == 2)
        #expect(Set(texts) == [Self.officeConfiguration, Self.pragueConfiguration])
    }

    @Test
    func readsARotatedQRCode() async throws {
        let image = try QRCodeImageFixture.pngImage(showing: [Self.officeConfiguration], rotatedByDegrees: 30)

        #expect(try await decoder.decodeTexts(in: image) == [Self.officeConfiguration])
    }

    @Test
    func readsAQRCodeShownTwiceOnce() async throws {
        let image = try QRCodeImageFixture.pngImage(showing: [Self.officeConfiguration, Self.officeConfiguration])

        #expect(try await decoder.decodeTexts(in: image) == [Self.officeConfiguration])
    }

    @Test
    func findsNothingInAnImageWithoutQRCodes() async throws {
        let image = try QRCodeImageFixture.pngImage(showing: [])

        #expect(try await decoder.decodeTexts(in: image).isEmpty)
    }

    @Test
    func rejectsDataThatIsNotAnImage() async {
        let decoder = decoder

        await #expect(throws: QRCodeDecodingError.unreadableImage) {
            try await decoder.decodeTexts(in: Data(Self.officeConfiguration.utf8))
        }
    }
}
