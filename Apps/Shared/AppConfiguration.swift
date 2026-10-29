import Foundation

struct AppConfiguration {
    private static let appGroupInfoKey = "SplitwayAppGroupIdentifier"
    private static let tunnelProviderInfoKey = "SplitwayTunnelProviderBundleIdentifier"
    private static let versionInfoKey = "CFBundleShortVersionString"
    private static let buildInfoKey = "CFBundleVersion"
    private static let storageDirectoryName = "Splitway"
    private static let groupStoragePath = "Library/Application Support"
    private static let logsPath = "Library/Logs/Splitway"
    private static let fallbackSubsystem = "Splitway"

    let storageDirectory: URL
    let logDirectory: URL
    let tunnelProviderBundleIdentifier: String
    let logSubsystem: String
    let version: String
    let build: String

    init(bundle: Bundle) {
        let groupIdentifier = bundle.object(forInfoDictionaryKey: Self.appGroupInfoKey) as? String
        let groupContainer = groupIdentifier.flatMap { identifier in
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
        }
        let storageParent =
            groupContainer?.appending(path: Self.groupStoragePath) ?? URL.applicationSupportDirectory
        storageDirectory = storageParent.appending(path: Self.storageDirectoryName)
        logDirectory = (groupContainer ?? FileManager.default.temporaryDirectory).appending(path: Self.logsPath)
        let tunnelProvider = bundle.object(forInfoDictionaryKey: Self.tunnelProviderInfoKey) as? String
        tunnelProviderBundleIdentifier = tunnelProvider ?? ""
        logSubsystem = bundle.bundleIdentifier ?? Self.fallbackSubsystem
        version = bundle.object(forInfoDictionaryKey: Self.versionInfoKey) as? String ?? ""
        build = bundle.object(forInfoDictionaryKey: Self.buildInfoKey) as? String ?? ""
    }
}
