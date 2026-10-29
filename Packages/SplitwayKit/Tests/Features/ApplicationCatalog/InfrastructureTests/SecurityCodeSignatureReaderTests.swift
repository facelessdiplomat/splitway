#if os(macOS)
    import ApplicationCatalog
    import ApplicationCatalogInfrastructure
    import Testing

    @Suite
    struct SecurityCodeSignatureReaderTests {
        @Test(arguments: [
            ("/Applications/Safari.app", "com.apple.Safari"),
            ("/System/Applications/Utilities/Terminal.app", "com.apple.Terminal"),
            ("/usr/bin/curl", "com.apple.curl"),
        ])
        func readsTheSignatureOfSystemCode(path: String, signingIdentifier: String) async throws {
            let signatures = try await SecurityCodeSignatureReader().signatures(ofBundleAt: path)

            #expect(signatures.main == CodeSignature(signingIdentifier: signingIdentifier, teamIdentifier: nil))
        }

        @Test
        func reportsCodeThatDoesNotExist() async {
            await #expect(throws: CodeSignatureReadingError.unreadable) {
                try await SecurityCodeSignatureReader().signatures(
                    ofBundleAt: "/Applications/Missing Splitway Test.app")
            }
        }
    }
#endif
