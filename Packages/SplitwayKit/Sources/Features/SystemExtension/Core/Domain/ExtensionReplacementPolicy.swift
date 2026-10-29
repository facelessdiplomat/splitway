public enum ExtensionReplacementPolicy {
    public static func action(
        replacing activeVersion: String,
        with bundledVersion: String
    ) -> ExtensionReplacementAction {
        guard let active = BundleVersion(activeVersion), let bundled = BundleVersion(bundledVersion) else {
            return .replace
        }
        return active == bundled ? .keep : .replace
    }
}
