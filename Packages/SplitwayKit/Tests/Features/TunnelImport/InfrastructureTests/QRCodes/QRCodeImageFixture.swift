import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

enum QRCodeImageFixture {
    private static let pixelsPerModule: CGFloat = 6
    private static let margin: CGFloat = 120
    private static let emptyCanvasSide: CGFloat = 240

    static func pngImage(showing messages: [String], rotatedByDegrees degrees: CGFloat = 0) throws -> Data {
        let codes = try messages.map(qrCodeImage)
        let side = codes.map { code in CGFloat(code.width) }.max() ?? emptyCanvasSide
        let canvasSize = CGSize(
            width: CGFloat(max(codes.count, 1)) * (side + margin) + margin,
            height: side + 2 * margin
        )
        let context = try whiteCanvas(of: canvasSize)
        for (index, code) in codes.enumerated() {
            let center = CGPoint(x: margin + side / 2 + CGFloat(index) * (side + margin), y: canvasSize.height / 2)
            draw(code, centeredAt: center, rotatedByDegrees: degrees, in: context)
        }
        return try pngData(of: try #require(context.makeImage()))
    }

    private static func qrCodeImage(for message: String) throws -> CGImage {
        let generator = CIFilter.qrCodeGenerator()
        generator.message = Data(message.utf8)
        generator.correctionLevel = "M"
        let code = try #require(generator.outputImage)
            .transformed(by: CGAffineTransform(scaleX: pixelsPerModule, y: pixelsPerModule))
        return try #require(CIContext().createCGImage(code, from: code.extent))
    }

    private static func whiteCanvas(of size: CGSize) throws -> CGContext {
        let context = try #require(
            CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        )
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))
        return context
    }

    private static func draw(
        _ code: CGImage,
        centeredAt center: CGPoint,
        rotatedByDegrees degrees: CGFloat,
        in context: CGContext
    ) {
        let width = CGFloat(code.width)
        let height = CGFloat(code.height)
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: degrees * .pi / 180)
        context.interpolationQuality = .none
        context.draw(code, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        context.restoreGState()
    }

    private static func pngData(of image: CGImage) throws -> Data {
        let data = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(destination, image, nil)
        try #require(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
