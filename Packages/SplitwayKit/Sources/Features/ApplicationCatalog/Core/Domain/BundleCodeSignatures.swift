public struct BundleCodeSignatures: Sendable, Hashable {
    public let main: CodeSignature?
    public let nested: [CodeSignature]

    public init(main: CodeSignature?, nested: [CodeSignature]) {
        self.main = main
        self.nested = nested
    }
}
