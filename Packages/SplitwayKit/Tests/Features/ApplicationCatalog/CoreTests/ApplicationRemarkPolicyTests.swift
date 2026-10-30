import AppRouting
import ApplicationCatalog
import ApplicationCatalogTestSupport
import Testing

@Suite
struct ApplicationRemarkPolicyTests {
    @Test
    func marksAnAppleApplicationBeforeItsSignatureIsRead() {
        let mail = InstalledApplication(
            kind: .application,
            name: "Mail",
            bundleIdentifier: "com.apple.mail",
            path: "/System/Applications/Mail.app",
            version: "16.0"
        )

        #expect(ApplicationRemarkPolicy.remarks(for: mail, identity: nil) == [.appleApplication])
    }

    @Test
    func doesNotMarkAnAppleCommandLineTool() throws {
        let curl = InstalledApplication(
            kind: .commandLineTool,
            name: "curl",
            bundleIdentifier: nil,
            path: "/usr/bin/curl",
            version: nil
        )
        let identity = try ApplicationIdentity(
            kind: .commandLineTool,
            displayName: "curl",
            path: "/usr/bin/curl",
            signingIdentifiers: ["com.apple.curl"]
        )

        #expect(ApplicationRemarkPolicy.remarks(for: curl, identity: identity).isEmpty)
    }

    @Test
    func marksAnApplicationWithoutDeveloperTeamAsMatchedByPath() throws {
        let homemade = InstalledApplication.fixture(named: "Homemade")
        let identity = try ApplicationIdentity(
            kind: .application,
            displayName: "Homemade",
            path: homemade.path,
            signingIdentifiers: ["Homemade-5555494495d1"]
        )

        #expect(ApplicationRemarkPolicy.remarks(for: homemade, identity: identity) == [.matchedByPath])
    }

    @Test
    func doesNotMarkAnApplicationSignedByItsDeveloper() throws {
        let identity = try ApplicationIdentity(
            kind: .application,
            displayName: "Browser",
            path: InstalledApplication.browser.path,
            signingIdentifiers: ["com.example.browser"],
            teamIdentifier: "ABCDE12345"
        )

        #expect(ApplicationRemarkPolicy.remarks(for: .browser, identity: identity).isEmpty)
    }

    @Test
    func waitsForTheSignatureBeforeMarkingAnApplicationOfAnotherDeveloper() {
        #expect(ApplicationRemarkPolicy.remarks(for: .browser, identity: nil).isEmpty)
    }

    @Test
    func describesASelectedApplicationThatTheScanDidNotFind() throws {
        let identity = try ApplicationIdentity(
            kind: .commandLineTool,
            displayName: "probe",
            path: "/opt/tools/probe",
            signingIdentifiers: ["probe"],
            bundleVersion: "2"
        )

        let application = InstalledApplication(representing: identity)

        #expect(
            application
                == InstalledApplication(
                    kind: .commandLineTool,
                    name: "probe",
                    bundleIdentifier: nil,
                    path: "/opt/tools/probe",
                    version: "2"
                )
        )
    }
}
