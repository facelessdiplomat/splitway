import Foundation

public protocol ApplicationIconLoader: Sendable {
    func iconData(forApplicationAt path: String) async -> Data?
}
