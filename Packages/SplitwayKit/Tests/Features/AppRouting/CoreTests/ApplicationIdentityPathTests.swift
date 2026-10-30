import AppRouting
import Testing

@Suite
struct ApplicationIdentityPathTests {
    private static let folderPathOfBundle = "/Applications/Homemade.app/"

    @Test
    func storesTheBundlePathWithoutTheTrailingSlashOfAFolder() throws {
        let identity = try ApplicationIdentity(
            kind: .application,
            displayName: "Homemade",
            path: Self.folderPathOfBundle
        )

        #expect(identity.path == "/Applications/Homemade.app")
    }

    @Test
    func recognizesTheExecutableOfABundleSelectedByItsFolderPath() throws {
        let identity = try ApplicationIdentity(
            kind: .application,
            displayName: "Homemade",
            path: Self.folderPathOfBundle
        )
        let executable = SourceApplication(
            signingIdentifier: nil,
            teamIdentifier: nil,
            executablePath: "/Applications/Homemade.app/Contents/MacOS/Homemade"
        )

        #expect(ApplicationMatcher([identity]).matches(executable))
    }

    @Test
    func rejectsAPathMadeOnlyOfSlashes() {
        #expect(throws: ApplicationIdentityError.emptyPath) {
            try ApplicationIdentity(kind: .commandLineTool, displayName: "Root", path: "//")
        }
    }
}
