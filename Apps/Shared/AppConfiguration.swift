import Foundation

struct AppConfiguration {
    private static let appGroupInfoKey = "SplitwayAppGroupIdentifier"
    private static let tunnelProviderInfoKey = "SplitwayTunnelProviderBundleIdentifier"
    private static let storageDirectoryName = "Splitway"
    private static let groupStoragePath = "Library/Application Support"

    let storageDirectory: URL
    let tunnelProviderBundleIdentifier: String

    init(bundle: Bundle) {
        let groupIdentifier = bundle.object(forInfoDictionaryKey: Self.appGroupInfoKey) as? String
        let groupContainer = groupIdentifier.flatMap { identifier in
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
        }
        let storageParent =
            groupContainer?.appending(path: Self.groupStoragePath) ?? URL.applicationSupportDirectory
        storageDirectory = storageParent.appending(path: Self.storageDirectoryName)
        let tunnelProvider = bundle.object(forInfoDictionaryKey: Self.tunnelProviderInfoKey) as? String
        tunnelProviderBundleIdentifier = tunnelProvider ?? ""
    }
}
