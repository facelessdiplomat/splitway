#if os(macOS)
    import ApplicationCatalog
    import Foundation
    import Security

    public struct SecurityCodeSignatureReader: CodeSignatureReader {
        private static let queue = DispatchQueue(label: "Splitway.CodeSignatures", qos: .userInitiated)

        public init() {}

        public func signatures(ofBundleAt path: String) async throws(CodeSignatureReadingError) -> BundleCodeSignatures
        {
            try await Self.queuedSignatures(ofBundleAt: path).get()
        }

        private static func queuedSignatures(ofBundleAt path: String) async
            -> Result<BundleCodeSignatures, CodeSignatureReadingError>
        {
            await withCheckedContinuation { continuation in
                queue.async {
                    continuation.resume(returning: readSignatures(ofBundleAt: path))
                }
            }
        }

        private static func readSignatures(ofBundleAt path: String) -> Result<
            BundleCodeSignatures, CodeSignatureReadingError
        > {
            guard FileManager.default.fileExists(atPath: path) else { return .failure(.unreadable) }
            let nested = NestedCodeEnumerator.nestedCodePaths(inBundleAt: path).compactMap(signature(ofCodeAt:))
            return .success(BundleCodeSignatures(main: signature(ofCodeAt: path), nested: nested))
        }

        private static func signature(ofCodeAt path: String) -> CodeSignature? {
            var staticCode: SecStaticCode?
            guard SecStaticCodeCreateWithPath(URL(filePath: path) as CFURL, [], &staticCode) == errSecSuccess,
                let staticCode
            else { return nil }
            var information: CFDictionary?
            let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
            guard SecCodeCopySigningInformation(staticCode, flags, &information) == errSecSuccess,
                let details = information as? [String: Any],
                let identifier = details[kSecCodeInfoIdentifier as String] as? String
            else { return nil }
            return CodeSignature(
                signingIdentifier: identifier,
                teamIdentifier: details[kSecCodeInfoTeamIdentifier as String] as? String
            )
        }
    }
#endif
