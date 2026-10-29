import AppRouting
import Testing

@Suite
struct ApplicationSelectionTests {
    @Test
    func describesAnApplicationWithItsHelpers() throws {
        let identity = try ApplicationIdentity(
            kind: .application,
            displayName: "Telegram",
            path: "/Applications/Telegram.app",
            signingIdentifiers: ["ru.keepcoder.Telegram", "ru.keepcoder.Telegram.Helper"],
            teamIdentifier: "6N38VWS5BX"
        )

        #expect(identity.signingIdentifiers == ["ru.keepcoder.Telegram", "ru.keepcoder.Telegram.Helper"])
        #expect(identity.teamIdentifier == "6N38VWS5BX")
    }

    @Test
    func sortsAndDeduplicatesSigningIdentifiersForStableStorage() throws {
        let identity = try ApplicationIdentity(
            kind: .commandLineTool,
            displayName: "curl",
            path: "/usr/bin/curl",
            signingIdentifiers: ["com.apple.curl", "com.apple.curl", "a.helper"]
        )

        #expect(identity.signingIdentifiers == ["a.helper", "com.apple.curl"])
    }

    @Test
    func rejectsIdentitiesWithoutANameOrPath() {
        #expect(throws: ApplicationIdentityError.emptyDisplayName) {
            try ApplicationIdentity(kind: .application, displayName: " ", path: "/Applications/App.app")
        }
        #expect(throws: ApplicationIdentityError.emptyPath) {
            try ApplicationIdentity(kind: .application, displayName: "App", path: "")
        }
    }

    @Test
    func keepsOneEntryPerPathInTheOrderOfFirstAppearance() throws {
        let telegram = try ApplicationIdentity(
            kind: .application, displayName: "Telegram", path: "/Applications/Telegram.app")
        let renamedTelegram = try ApplicationIdentity(
            kind: .application, displayName: "TG", path: "/Applications/Telegram.app")
        let curl = try ApplicationIdentity(kind: .commandLineTool, displayName: "curl", path: "/usr/bin/curl")

        let selection = ApplicationSelection([curl, telegram, renamedTelegram])

        #expect(selection.applications == [curl, telegram])
    }

    @Test(arguments: ["telegram", "youtube", "custom-7f3a"])
    func acceptsServiceIdentifiers(_ text: String) throws {
        #expect(try ServiceIdentifier(text).description == text)
    }

    @Test(arguments: ["", "Telegram", "you tube", "-telegram", "telegram_web"])
    func rejectsMalformedServiceIdentifiers(_ text: String) {
        #expect(throws: ServiceIdentifierError.malformed) {
            try ServiceIdentifier(text)
        }
    }
}
