import AppRouting
import ApplicationCatalog
import ApplicationCatalogTestSupport
import Testing

@Suite
struct ApplicationCatalogUseCaseTests {
    private static let browserSignatures = BundleCodeSignatures(
        main: CodeSignature(signingIdentifier: "com.example.browser", teamIdentifier: "BROWSER123"),
        nested: [CodeSignature(signingIdentifier: "com.example.browser.helper", teamIdentifier: "BROWSER123")]
    )

    @Test
    func listsInstalledApplicationsByName() async {
        let scanner = InMemoryApplicationBundleScanner(applications: [
            .fixture(named: "Terminal"), .fixture(named: "Mail"),
        ])

        let applications = await LoadInstalledApplicationsUseCase(scanner: scanner).execute()

        #expect(applications.map(\.name) == ["Mail", "Terminal"])
    }

    @Test
    func resolvesTheIdentityFromTheSignatures() async throws {
        let reader = InMemoryCodeSignatureReader(signaturesByPath: ["/Applications/Browser.app": Self.browserSignatures]
        )

        let identity = try await ResolveApplicationIdentityUseCase(signatures: reader).execute(for: .browser)

        #expect(identity.signingIdentifiers == ["com.example.browser", "com.example.browser.helper"])
        #expect(identity.teamIdentifier == "BROWSER123")
    }

    @Test
    func fallsBackToThePathWhenTheSignatureCannotBeRead() async throws {
        let reader = InMemoryCodeSignatureReader(signaturesByPath: [:])

        let identity = try await ResolveApplicationIdentityUseCase(signatures: reader).execute(for: .browser)

        #expect(identity.signingIdentifiers.isEmpty)
        #expect(identity.teamIdentifier == nil)
        #expect(identity.path == "/Applications/Browser.app")
    }

    @Test
    func rebuildsTheIdentityOfAnUpdatedApplication() async throws {
        let outdated = try ApplicationIdentity(
            kind: .application,
            displayName: "Browser",
            path: "/Applications/Browser.app",
            signingIdentifiers: ["com.example.browser"],
            teamIdentifier: "BROWSER123",
            bundleVersion: "1.0"
        )
        let reader = InMemoryCodeSignatureReader(signaturesByPath: ["/Applications/Browser.app": Self.browserSignatures]
        )
        let refresh = RefreshSelectedApplicationsUseCase(resolve: ResolveApplicationIdentityUseCase(signatures: reader))

        let refreshed = await refresh.execute(ApplicationSelection([outdated]), installed: [.browser])

        let identity = try #require(refreshed.applications.first)
        #expect(identity.bundleVersion == "2.0")
        #expect(identity.signingIdentifiers == ["com.example.browser", "com.example.browser.helper"])
    }

    @Test
    func keepsIdentitiesOfUnchangedOrMissingApplications() async throws {
        let current = try ApplicationIdentity(
            kind: .application,
            displayName: "Browser",
            path: "/Applications/Browser.app",
            signingIdentifiers: ["com.example.browser"],
            bundleVersion: "2.0"
        )
        let missing = try ApplicationIdentity(kind: .application, displayName: "Gone", path: "/Applications/Gone.app")
        let refresh = RefreshSelectedApplicationsUseCase(
            resolve: ResolveApplicationIdentityUseCase(signatures: InMemoryCodeSignatureReader(signaturesByPath: [:]))
        )

        let refreshed = await refresh.execute(ApplicationSelection([current, missing]), installed: [.browser])

        #expect(refreshed == ApplicationSelection([current, missing]))
    }
}
