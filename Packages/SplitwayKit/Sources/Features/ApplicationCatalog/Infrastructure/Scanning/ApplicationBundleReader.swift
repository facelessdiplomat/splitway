import ApplicationCatalog
import Foundation

enum ApplicationBundleReader {
    private static let bundleExtension = "app"
    private static let identifierKey = "CFBundleIdentifier"
    private static let shortVersionKey = "CFBundleShortVersionString"
    private static let buildVersionKey = "CFBundleVersion"

    static func infoFile(ofBundleAt path: String) -> URL {
        URL(filePath: path).appending(path: "Contents/Info.plist")
    }

    static func application(at path: String) -> InstalledApplication? {
        guard let data = try? Data(contentsOf: infoFile(ofBundleAt: path)),
            let info = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        return InstalledApplication(
            kind: .application,
            name: displayName(ofBundleAt: path),
            bundleIdentifier: info[identifierKey] as? String,
            path: path,
            version: (info[shortVersionKey] as? String) ?? (info[buildVersionKey] as? String)
        )
    }

    private static func displayName(ofBundleAt path: String) -> String {
        let name = FileManager.default.displayName(atPath: path)
        let suffix = ".\(bundleExtension)"
        return name.hasSuffix(suffix) ? String(name.dropLast(suffix.count)) : name
    }
}
