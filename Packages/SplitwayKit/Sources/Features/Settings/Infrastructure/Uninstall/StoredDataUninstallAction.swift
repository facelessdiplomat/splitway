import Foundation
import Settings

public struct StoredDataUninstallAction: UninstallAction {
    public let step = UninstallStep.removeAppData
    private let directories: [URL]
    private let preferencesDomain: String?

    public init(directories: [URL], preferencesDomain: String?) {
        self.directories = directories
        self.preferencesDomain = preferencesDomain
    }

    public func perform() async throws(UninstallStepFailure) {
        var hasFailure = false
        for directory in directories where FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.removeItem(at: directory)
            } catch {
                hasFailure = true
            }
        }
        if let preferencesDomain {
            UserDefaults.standard.removePersistentDomain(forName: preferencesDomain)
        }
        if hasFailure {
            throw UninstallStepFailure()
        }
    }
}
