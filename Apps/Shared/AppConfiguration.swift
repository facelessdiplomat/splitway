import Foundation

struct AppConfiguration {
    private static let appGroupInfoKey = "SplitwayAppGroupIdentifier"
    private static let tunnelProviderInfoKey = "SplitwayTunnelProviderBundleIdentifier"
    private static let extensionMachServiceInfoKey = "SplitwayExtensionMachServiceName"
    private static let versionInfoKey = "CFBundleShortVersionString"
    private static let buildInfoKey = "CFBundleVersion"
    private static let storageDirectoryName = "Splitway"
    private static let groupStoragePath = "Library/Application Support"
    private static let logsPath = "Library/Logs/Splitway"
    private static let fallbackSubsystem = "Splitway"
    private static let temporaryStorageArgument = "SplitwayUsesTemporaryStorage"

    let storageDirectory: URL
    let logDirectory: URL
    let tunnelProviderBundleIdentifier: String
    let extensionMachServiceName: String
    let logSubsystem: String
    let version: String
    let build: String
    let systemDescription: String

    init(bundle: Bundle) {
        if UserDefaults.standard.bool(forKey: Self.temporaryStorageArgument) {
            let temporaryRoot = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            storageDirectory = temporaryRoot.appending(path: Self.storageDirectoryName)
            logDirectory = temporaryRoot.appending(path: Self.logsPath)
        } else {
            let groupContainer = Self.groupContainer(of: bundle)
            let storageParent =
                groupContainer?.appending(path: Self.groupStoragePath) ?? URL.applicationSupportDirectory
            storageDirectory = storageParent.appending(path: Self.storageDirectoryName)
            logDirectory = (groupContainer ?? FileManager.default.temporaryDirectory).appending(path: Self.logsPath)
        }
        let tunnelProvider = bundle.object(forInfoDictionaryKey: Self.tunnelProviderInfoKey) as? String
        tunnelProviderBundleIdentifier = tunnelProvider ?? ""
        let extensionMachService = bundle.object(forInfoDictionaryKey: Self.extensionMachServiceInfoKey) as? String
        extensionMachServiceName = extensionMachService ?? ""
        logSubsystem = bundle.bundleIdentifier ?? Self.fallbackSubsystem
        version = bundle.object(forInfoDictionaryKey: Self.versionInfoKey) as? String ?? ""
        build = bundle.object(forInfoDictionaryKey: Self.buildInfoKey) as? String ?? ""
        systemDescription = Self.systemDescription(of: ProcessInfo.processInfo.operatingSystemVersion)
    }

    private static func systemDescription(of version: OperatingSystemVersion) -> String {
        "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private static func groupContainer(of bundle: Bundle) -> URL? {
        let groupIdentifier = bundle.object(forInfoDictionaryKey: appGroupInfoKey) as? String
        return groupIdentifier.flatMap { identifier in
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
        }
    }
}
