import ApplicationCatalog
import Foundation

public struct InMemoryApplicationIconLoader: ApplicationIconLoader {
    private let iconsByPath: [String: Data]

    public init(iconsByPath: [String: Data] = [:]) {
        self.iconsByPath = iconsByPath
    }

    public func iconData(forApplicationAt path: String) async -> Data? {
        iconsByPath[path]
    }
}
