import AppRouting
import ApplicationCatalog

extension InstalledApplication {
    public static let browser = InstalledApplication(
        kind: .application,
        name: "Browser",
        bundleIdentifier: "com.example.browser",
        path: "/Applications/Browser.app",
        version: "2.0"
    )

    public static func fixture(
        named name: String,
        kind: ApplicationKind = .application,
        version: String? = "1.0"
    ) -> InstalledApplication {
        InstalledApplication(
            kind: kind,
            name: name,
            bundleIdentifier: kind == .application ? "com.example.\(name.lowercased())" : nil,
            path: kind == .application ? "/Applications/\(name).app" : "/usr/local/bin/\(name)",
            version: version
        )
    }
}
