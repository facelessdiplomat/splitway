import Foundation
import Testing
import TunnelConfigurationTestSupport
import TunnelImport

@Suite
struct PrepareImportUseCaseTests {
    @Test
    func acceptsPastedTextSurroundedByExtraWhitespace() async throws {
        let paddedText =
            "\n \t\n" + WgQuickFixtures.minimal.replacingOccurrences(of: "\n", with: "  \t\n") + "\n\n   "

        let preview = try await ImportTestEnvironment().prepareImport().execute([.text(paddedText)])

        let candidate = try #require(preview.candidates.only)
        #expect(candidate.source == .text)
        #expect(candidate.proposedName.description == ImportTestEnvironment.fallbackName)
        #expect(candidate.isImportable)
        #expect(candidate.issues.isEmpty)
    }

    @Test
    func namesAFileWithoutExtensionAfterTheFile() async throws {
        let preview = try await ImportTestEnvironment().prepareImport()
            .execute([.file(name: "office", contents: Data(WgQuickFixtures.minimal.utf8))])

        let candidate = try #require(preview.candidates.only)
        #expect(candidate.source == .file(name: "office"))
        #expect(candidate.proposedName.description == "office")
        #expect(candidate.isImportable)
    }

    @Test
    func previewsEveryConfigurationOfAnArchive() async throws {
        let environment = ImportTestEnvironment(archives: [
            ImportTestEnvironment.archiveData: .success([
                ArchivedConfigurationFile(fileName: "Office.conf", contents: Data(WgQuickFixtures.minimal.utf8)),
                ArchivedConfigurationFile(fileName: "Broken.conf", contents: Data("[Interface]\nAddress = x\n".utf8)),
            ])
        ])

        let preview = try await environment.prepareImport()
            .execute([.file(name: "export.zip", contents: ImportTestEnvironment.archiveData)])

        #expect(
            preview.candidates.map(\.source) == [
                .archiveEntry(archiveName: "export.zip", fileName: "Office.conf"),
                .archiveEntry(archiveName: "export.zip", fileName: "Broken.conf"),
            ]
        )
        #expect(preview.candidates.map(\.proposedName.description) == ["Office", "Broken"])
        #expect(preview.candidates.map(\.isImportable) == [true, false])
        #expect(preview.candidates.map(\.errors.isEmpty) == [true, false])
        #expect(preview.failures.isEmpty)
    }

    @Test
    func keepsWarningsOfImportableConfigurations() async throws {
        let preview = try await ImportTestEnvironment().prepareImport()
            .execute([.file(name: "hooks.conf", contents: Data(WgQuickFixtures.wgQuickHooks.utf8))])

        let candidate = try #require(preview.candidates.only)
        #expect(candidate.isImportable)
        #expect(candidate.errors.isEmpty)
        #expect(!candidate.warnings.isEmpty)
    }

    @Test
    func recognizesAConfigurationThatIsAlreadyInTheLibrary() async throws {
        let environment = ImportTestEnvironment()
        try await environment.storeTunnel(named: "Office", fixture: WgQuickFixtures.minimal)

        let preview = try await environment.prepareImport()
            .execute([.file(name: "Office.conf", contents: Data(WgQuickFixtures.minimal.utf8))])

        let candidate = try #require(preview.candidates.only)
        #expect(candidate.alreadyImportedAs?.description == "Office")
        #expect(candidate.uniqueName.description == "Office 2")
        #expect(candidate.hasNameConflict)
    }

    @Test
    func remembersTheNamesAlreadyInTheLibrary() async throws {
        let environment = ImportTestEnvironment()
        try await environment.storeTunnel(named: "Office", fixture: WgQuickFixtures.minimal)

        let preview = try await environment.prepareImport().execute([.text(WgQuickFixtures.full)])

        #expect(preview.existingNames.map(\.description) == ["Office"])
    }

    @Test
    func reportsFilesThatCouldNotBeRead() async throws {
        let preview = try await ImportTestEnvironment().prepareImport()
            .execute([.text(WgQuickFixtures.minimal)], unreadableFileNames: ["locked.conf"])

        #expect(preview.failures == [ImportSourceFailure(source: .file(name: "locked.conf"), reason: .unreadable)])
        #expect(preview.candidates.count == 1)
    }

    @Test
    func keepsNamesUniqueWithinOneImport() async throws {
        let preview = try await ImportTestEnvironment().prepareImport().execute([
            .file(name: "Office.conf", contents: Data(WgQuickFixtures.minimal.utf8)),
            .file(name: "office.conf", contents: Data(WgQuickFixtures.full.utf8)),
        ])

        #expect(preview.candidates.map(\.uniqueName.description) == ["Office", "office 2"])
        #expect(preview.candidates.map(\.alreadyImportedAs) == [nil, nil])
    }

    @Test
    func reportsFilesThatAreNeitherConfigurationsNorArchives() async throws {
        let preview = try await ImportTestEnvironment().prepareImport()
            .execute([.file(name: "photo.jpg", contents: Data([0xFF, 0xD8, 0xFF, 0xE0]))])

        #expect(preview.candidates.isEmpty)
        #expect(preview.failures == [ImportSourceFailure(source: .file(name: "photo.jpg"), reason: .notText)])
    }

    @Test
    func reportsArchivesThatExceedTheLimits() async throws {
        let environment = ImportTestEnvironment(archives: [
            ImportTestEnvironment.archiveData: .failure(.tooManyConfigurationFiles(limit: 100))
        ])

        let preview = try await environment.prepareImport()
            .execute([.file(name: "export.zip", contents: ImportTestEnvironment.archiveData)])

        #expect(
            preview.failures == [
                ImportSourceFailure(
                    source: .file(name: "export.zip"),
                    reason: .archiveRejected(.tooManyConfigurationFiles(limit: 100))
                )
            ]
        )
    }

    @Test
    func reportsArchivesWithoutConfigurations() async throws {
        let environment = ImportTestEnvironment(archives: [ImportTestEnvironment.archiveData: .success([])])

        let preview = try await environment.prepareImport()
            .execute([.file(name: "export.zip", contents: ImportTestEnvironment.archiveData)])

        #expect(
            preview.failures == [
                ImportSourceFailure(source: .file(name: "export.zip"), reason: .noConfigurationsInArchive)
            ]
        )
    }

    @Test
    func treatsAFileNamedLikeAnArchiveAsOne() async throws {
        let preview = try await ImportTestEnvironment().prepareImport()
            .execute([.file(name: "Export.ZIP", contents: Data("not really an archive".utf8))])

        #expect(
            preview.failures == [
                ImportSourceFailure(source: .file(name: "Export.ZIP"), reason: .archiveRejected(.unreadableArchive))
            ]
        )
    }
}

extension Array {
    fileprivate var only: Element? {
        count == 1 ? first : nil
    }
}
