import AppRouting

extension InstalledApplication {
    public init(representing identity: ApplicationIdentity) {
        self.init(
            kind: identity.kind,
            name: identity.displayName,
            bundleIdentifier: nil,
            path: identity.path,
            version: identity.bundleVersion
        )
    }
}
