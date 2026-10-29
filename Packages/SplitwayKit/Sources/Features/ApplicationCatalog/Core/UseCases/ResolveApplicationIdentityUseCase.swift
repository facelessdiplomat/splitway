import AppRouting

public struct ResolveApplicationIdentityUseCase: Sendable {
    private static let unsigned = BundleCodeSignatures(main: nil, nested: [])

    private let signatures: any CodeSignatureReader

    public init(signatures: any CodeSignatureReader) {
        self.signatures = signatures
    }

    public func execute(for application: InstalledApplication) async throws(ApplicationIdentityError)
        -> ApplicationIdentity
    {
        let bundleSignatures = (try? await signatures.signatures(ofBundleAt: application.path)) ?? Self.unsigned
        return try ApplicationIdentityBuilder.identity(of: application, signatures: bundleSignatures)
    }
}
