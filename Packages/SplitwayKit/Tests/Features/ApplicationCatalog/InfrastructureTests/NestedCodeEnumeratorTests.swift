import ApplicationCatalogInfrastructure
import Foundation
import Testing

@Suite
final class NestedCodeEnumeratorTests {
    private let fixture = ApplicationBundleFixture()

    deinit {
        fixture.remove()
    }

    @Test
    func findsHelpersServicesAndHelperExecutables() throws {
        let bundle = try fixture.makeApplication(
            "Browser.app", bundleIdentifier: "com.example.browser", version: "1.0")
        try fixture.makeDirectory(
            "Browser.app/Contents/Frameworks/Browser Framework.framework/Helpers/Browser Helper.app")
        try fixture.makeDirectory("Browser.app/Contents/XPCServices/Updater.xpc")
        try fixture.makeExecutable("Browser.app/Contents/Helpers/crash_handler")
        try fixture.makeDirectory("Browser.app/Contents/Resources/Bundled Sample.app")

        let nested = NestedCodeEnumerator.nestedCodePaths(inBundleAt: bundle.path(percentEncoded: false))

        #expect(
            nested == [
                fixture.path(
                    "Browser.app/Contents/Frameworks/Browser Framework.framework/Helpers/Browser Helper.app"),
                fixture.path("Browser.app/Contents/Helpers/crash_handler"),
                fixture.path("Browser.app/Contents/XPCServices/Updater.xpc"),
            ])
    }
}
