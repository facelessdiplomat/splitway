import AppKit
import ApplicationCatalog
import Foundation
import Synchronization

public final class WorkspaceIconLoader: ApplicationIconLoader {
    private static let queue = DispatchQueue(label: "Splitway.ApplicationIcons", qos: .userInitiated)
    private static let iconSide: CGFloat = 64

    private let cache = Mutex<[String: Data]>([:])

    public init() {}

    public func iconData(forApplicationAt path: String) async -> Data? {
        if let cached = cache.withLock({ icons in icons[path] }) {
            return cached
        }
        let data = await withCheckedContinuation { continuation in
            Self.queue.async {
                continuation.resume(returning: Self.renderIcon(ofFileAt: path))
            }
        }
        if let data {
            cache.withLock { icons in icons[path] = data }
        }
        return data
    }

    private static func renderIcon(ofFileAt path: String) -> Data? {
        let icon = NSWorkspace.shared.icon(forFile: path)
        var rect = NSRect(x: 0, y: 0, width: iconSide, height: iconSide)
        guard let image = icon.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return nil }
        return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    }
}
