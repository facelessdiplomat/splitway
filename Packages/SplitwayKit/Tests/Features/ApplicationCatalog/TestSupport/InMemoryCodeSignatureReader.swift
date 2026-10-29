import ApplicationCatalog

public struct InMemoryCodeSignatureReader: CodeSignatureReader {
    private let signaturesByPath: [String: BundleCodeSignatures]

    public init(signaturesByPath: [String: BundleCodeSignatures]) {
        self.signaturesByPath = signaturesByPath
    }

    public func signatures(ofBundleAt path: String) async throws(CodeSignatureReadingError) -> BundleCodeSignatures {
        guard let signatures = signaturesByPath[path] else { throw .unreadable }
        return signatures
    }
}
