import AppRouting

public enum ApplicationIdentityBuilder {
    public static func identity(
        of application: InstalledApplication,
        signatures: BundleCodeSignatures
    ) throws(ApplicationIdentityError) -> ApplicationIdentity {
        try ApplicationIdentity(
            kind: application.kind,
            displayName: application.name,
            path: application.path,
            signingIdentifiers: signingIdentifiers(of: signatures),
            teamIdentifier: signatures.main?.teamIdentifier,
            bundleVersion: application.version
        )
    }

    private static func signingIdentifiers(of signatures: BundleCodeSignatures) -> [String] {
        guard let main = signatures.main else { return [] }
        let helpers = signatures.nested.filter { nested in nested.teamIdentifier == main.teamIdentifier }
        return [main.signingIdentifier] + helpers.map(\.signingIdentifier)
    }
}
