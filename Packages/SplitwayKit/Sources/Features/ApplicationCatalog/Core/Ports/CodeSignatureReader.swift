public protocol CodeSignatureReader: Sendable {
    func signatures(ofBundleAt path: String) async throws(CodeSignatureReadingError) -> BundleCodeSignatures
}
