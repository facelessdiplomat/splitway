#if os(macOS)
    import ApplicationCatalog
    import ApplicationCatalogInfrastructure
    import Foundation
    import Testing

    @Suite
    final class FileSystemApplicationScannerTests {
        private static let warmScanBudget = Duration.seconds(2)

        private let fixture = ApplicationBundleFixture()

        deinit {
            fixture.remove()
        }

        @Test
        func findsApplicationsOneFolderDeepOnlyOnce() async throws {
            let editor = try fixture.makeApplication(
                "Editor.app", bundleIdentifier: "com.example.editor", version: "3.1")
            try fixture.makeApplication("Suite/Viewer.app", bundleIdentifier: "com.example.viewer", version: "1.0")
            try fixture.makeApplication("Deep/Inner/Hidden.app", bundleIdentifier: "com.example.hidden", version: "1.0")
            try fixture.makeSymbolicLink("Editor Shortcut.app", to: editor)
            let scanner = FileSystemApplicationScanner(directories: [fixture.root], includesRunningApplications: false)

            let applications = await scanner.installedApplications().sorted { first, second in first.name < second.name
            }

            #expect(applications.map(\.name) == ["Editor", "Viewer"])
            #expect(applications.map(\.bundleIdentifier) == ["com.example.editor", "com.example.viewer"])
            #expect(applications.map(\.version) == ["3.1", "1.0"])
            #expect(applications.first?.path == fixture.path("Editor.app"))
        }

        @Test
        func scansThisMacWithAWarmCacheWithinTheBudget() async {
            let scanner = FileSystemApplicationScanner()
            let firstScan = await scanner.installedApplications()

            let start = ContinuousClock.now
            let secondScan = await scanner.installedApplications()
            let elapsed = ContinuousClock.now - start

            #expect(!firstScan.isEmpty)
            #expect(secondScan == firstScan)
            #expect(elapsed < Self.warmScanBudget, "A warm scan of \(secondScan.count) applications took \(elapsed)")
        }
    }
#endif
