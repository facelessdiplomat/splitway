#if os(macOS)
    import ApplicationCatalog
    import ApplicationCatalogInfrastructure
    import Foundation
    import Testing

    @Suite
    final class FileSystemApplicationFileReaderTests {
        private let fixture = ApplicationBundleFixture()
        private let reader = FileSystemApplicationFileReader()

        deinit {
            fixture.remove()
        }

        @Test
        func readsADroppedApplicationBundle() async throws {
            let bundle = try fixture.makeApplication(
                "Editor.app", bundleIdentifier: "com.example.editor", version: "3.1")

            let application = await reader.application(at: bundle.path(percentEncoded: false) + "/")

            #expect(
                application
                    == InstalledApplication(
                        kind: .application,
                        name: "Editor",
                        bundleIdentifier: "com.example.editor",
                        path: fixture.path("Editor.app"),
                        version: "3.1"
                    )
            )
        }

        @Test
        func readsAnExecutableAsACommandLineToolAtItsRealPath() async throws {
            try fixture.makeExecutable("bin/probe")
            try fixture.makeSymbolicLink("probe-link", to: fixture.root.appending(path: "bin/probe"))
            let link = fixture.root.appending(path: "probe-link").path(percentEncoded: false)

            let application = await reader.application(at: link)

            #expect(
                application
                    == InstalledApplication(
                        kind: .commandLineTool,
                        name: "probe",
                        bundleIdentifier: nil,
                        path: fixture.path("bin/probe"),
                        version: nil
                    )
            )
        }

        @Test
        func readsAnExecutableThatThisProcessMayNotRunAsACommandLineTool() async throws {
            try fixture.makeExecutable("bin/sandboxed")
            try fixture.denyExecutionToEveryone("bin/sandboxed")

            let application = await reader.application(at: fixture.path("bin/sandboxed"))

            #expect(application?.kind == .commandLineTool)
            #expect(application?.name == "sandboxed")
        }

        @Test
        func rejectsAFileThatIsNeitherAnApplicationNorAnExecutable() async throws {
            try fixture.makeDirectory("Documents")
            try Data("notes".utf8).write(to: fixture.root.appending(path: "notes.txt"))
            let missingBundle = fixture.root.appending(path: "Missing.app").path(percentEncoded: false)

            let directory = await reader.application(at: fixture.path("Documents"))
            let document = await reader.application(at: fixture.path("notes.txt"))
            let missing = await reader.application(at: missingBundle)

            #expect(directory == nil)
            #expect(document == nil)
            #expect(missing == nil)
        }
    }
#endif
