import AppRouting

public enum ApplicationRemarkPolicy {
    private static let appleBundleIdentifierPrefix = "com.apple."
    private static let appleCodeLocations = ["/System/", "/usr/bin/", "/usr/sbin/", "/usr/libexec/", "/bin/", "/sbin/"]

    public static func remarks(for application: InstalledApplication, identity: ApplicationIdentity?)
        -> [ApplicationRemark]
    {
        if isAppleCode(application) {
            return application.kind == .application ? [.appleApplication] : []
        }
        guard let identity, identity.teamIdentifier == nil else { return [] }
        return [.matchedByPath]
    }

    private static func isAppleCode(_ application: InstalledApplication) -> Bool {
        application.bundleIdentifier?.hasPrefix(appleBundleIdentifierPrefix) == true
            || appleCodeLocations.contains { location in application.path.hasPrefix(location) }
    }
}
