import ApplicationCatalog

public struct InMemoryCodeSignatureReader: CodeSignatureReader {
    private let signaturesByPath: [String: BundleCodeSignatures]
    private let access: InMemoryChosenFileAccess?

    public init(
        signaturesByPath: [String: BundleCodeSignatures],
        readableWhileOpenIn access: InMemoryChosenFileAccess? = nil
    ) {
        self.signaturesByPath = signaturesByPath
        self.access = access
    }

    public func signatures(ofBundleAt path: String) async throws(CodeSignatureReadingError) -> BundleCodeSignatures {
        if let access, !access.isOpen(path) {
            throw .unreadable
        }
        guard let signatures = signaturesByPath[path] else { throw .unreadable }
        return signatures
    }
}
