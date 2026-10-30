import AppRouting
import ApplicationCatalog
import ImageIO
import SwiftUI

struct ApplicationIconView: View {
    private static let side: CGFloat = 24

    let path: String
    let kind: ApplicationKind
    let iconLoader: any ApplicationIconLoader
    @State private var icon: CGImage?

    var body: some View {
        Group {
            if let icon {
                Image(decorative: icon, scale: 1)
                    .resizable()
                    .interpolation(.high)
            } else {
                Image(systemName: kind == .commandLineTool ? "terminal" : "app.dashed")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: Self.side, height: Self.side)
        .task(id: path) {
            icon = await iconLoader.iconData(forApplicationAt: path).flatMap(Self.image(decoding:))
        }
    }

    private static func image(decoding data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
