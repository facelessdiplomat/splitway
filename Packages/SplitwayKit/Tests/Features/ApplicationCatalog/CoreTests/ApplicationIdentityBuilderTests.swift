import AppRouting
import ApplicationCatalog
import ApplicationCatalogTestSupport
import Testing

@Suite
struct ApplicationIdentityBuilderTests {
    private static let browserTeam = "BROWSER123"

    @Test
    func takesTheHelpersSignedByTheSameTeam() throws {
        let signatures = BundleCodeSignatures(
            main: CodeSignature(signingIdentifier: "com.example.browser", teamIdentifier: Self.browserTeam),
            nested: [
                CodeSignature(signingIdentifier: "com.example.browser.helper", teamIdentifier: Self.browserTeam),
                CodeSignature(
                    signingIdentifier: "com.example.browser.helper.renderer", teamIdentifier: Self.browserTeam),
                CodeSignature(signingIdentifier: "org.vendor.updater", teamIdentifier: "VENDOR9999"),
            ]
        )

        let identity = try ApplicationIdentityBuilder.identity(of: .browser, signatures: signatures)

        #expect(
            identity.signingIdentifiers == [
                "com.example.browser", "com.example.browser.helper", "com.example.browser.helper.renderer",
            ])
        #expect(identity.teamIdentifier == Self.browserTeam)
        #expect(identity.bundleVersion == "2.0")
        #expect(identity.path == "/Applications/Browser.app")
    }

    @Test
    func matchesAnUnsignedApplicationByItsPath() throws {
        let identity = try ApplicationIdentityBuilder.identity(
            of: .browser,
            signatures: BundleCodeSignatures(main: nil, nested: [])
        )
        let matcher = ApplicationMatcher([identity])

        #expect(identity.signingIdentifiers.isEmpty)
        #expect(
            matcher.matches(
                SourceApplication(
                    signingIdentifier: nil,
                    teamIdentifier: nil,
                    executablePath: "/Applications/Browser.app/Contents/MacOS/Browser"
                )
            ))
    }
}
