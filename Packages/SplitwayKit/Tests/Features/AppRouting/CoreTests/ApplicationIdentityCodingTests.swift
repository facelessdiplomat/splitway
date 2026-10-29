import AppRouting
import Foundation
import Testing

@Suite
struct ApplicationIdentityCodingTests {
    @Test
    func keepsTheBundleVersionThroughCoding() throws {
        let identity = try ApplicationIdentity(
            kind: .application,
            displayName: "Browser",
            path: "/Applications/Browser.app",
            signingIdentifiers: ["com.example.browser"],
            teamIdentifier: "BROWSER123",
            bundleVersion: "2.0"
        )

        let decoded = try JSONDecoder().decode(ApplicationIdentity.self, from: JSONEncoder().encode(identity))

        #expect(decoded == identity)
        #expect(decoded.bundleVersion == "2.0")
    }

    @Test
    func readsIdentitiesSavedWithoutABundleVersion() throws {
        let json = Data(#"{"kind":"application","displayName":"Browser","path":"/Applications/Browser.app"}"#.utf8)

        #expect(try JSONDecoder().decode(ApplicationIdentity.self, from: json).bundleVersion == nil)
    }
}
