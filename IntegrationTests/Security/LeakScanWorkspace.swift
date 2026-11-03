import Foundation
import Security
import Testing

struct LeakScanWorkspace {
    private static let appGroupInfoKey = "SplitwayAppGroupIdentifier"

    let appGroupContainer: URL
    let applicationContainer: URL
    let groupDefaults: UserDefaults?
    let storageDirectory: URL
    let logDirectory: URL
    let slotPreferencesFile: URL
    let keychainService: String
    private let receivedFilesDirectory: URL

    init() throws {
        let groupIdentifier = try #require(Bundle.main.object(forInfoDictionaryKey: Self.appGroupInfoKey) as? String)
        appGroupContainer = try #require(
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
        )
        applicationContainer = URL(filePath: NSHomeDirectory())
        groupDefaults = UserDefaults(suiteName: groupIdentifier)
        let runName = "SplitwayLeakScan-\(UUID().uuidString)"
        storageDirectory = appGroupContainer.appending(path: "Library/Application Support/\(runName)")
        logDirectory = appGroupContainer.appending(path: "Library/Logs/\(runName)")
        slotPreferencesFile = storageDirectory.appending(path: "vpn-preferences.plist")
        keychainService = "splitway-leak-scan-\(UUID().uuidString)"
        receivedFilesDirectory = FileManager.default.temporaryDirectory.appending(path: "\(runName)-Received")
    }

    func receive(_ text: String, named name: String) throws -> URL {
        try FileManager.default.createDirectory(at: receivedFilesDirectory, withIntermediateDirectories: true)
        let copy = receivedFilesDirectory.appending(path: name)
        try Data(text.utf8).write(to: copy)
        return copy
    }

    func discardReceivedFiles() {
        try? FileManager.default.removeItem(at: receivedFilesDirectory)
    }

    func plant(_ contents: Data, named name: String) throws -> URL {
        try FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        let file = storageDirectory.appending(path: name)
        try contents.write(to: file)
        return file
    }

    func removeEverything() {
        for item in [storageDirectory, logDirectory, receivedFilesDirectory] {
            try? FileManager.default.removeItem(at: item)
        }
        let serviceItems: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecUseDataProtectionKeychain: true,
        ]
        SecItemDelete(serviceItems as CFDictionary)
    }
}
