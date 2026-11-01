import Foundation
import Settings
import SettingsInfrastructure
import Testing

@Suite
struct StoredDataUninstallActionTests {
    @Test
    func removesTheDirectoriesAndThePreferences() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let storage = root.appending(path: "Splitway")
        let logs = root.appending(path: "Logs")
        for directory in [storage, logs] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data("record".utf8).write(to: directory.appending(path: "file"))
        }
        let domain = "test.splitway.\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: domain))
        preferences.set(true, forKey: "Splitway.hasCompletedOnboarding")
        defer { try? FileManager.default.removeItem(at: root) }

        try await StoredDataUninstallAction(directories: [storage, logs], preferencesDomain: domain).perform()

        #expect(!FileManager.default.fileExists(atPath: storage.path))
        #expect(!FileManager.default.fileExists(atPath: logs.path))
        #expect(UserDefaults.standard.persistentDomain(forName: domain)?.isEmpty ?? true)
    }

    @Test
    func treatsAMissingDirectoryAsRemoved() async throws {
        let missing = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

        try await StoredDataUninstallAction(directories: [missing], preferencesDomain: nil).perform()

        #expect(!FileManager.default.fileExists(atPath: missing.path))
    }
}
