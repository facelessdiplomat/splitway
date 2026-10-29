import Foundation
import Testing
import TunnelImport
import TunnelImportInfrastructure

@Suite
struct ZIPArchiveReaderTests {
    private static let sizeLimit = 10 * 1024 * 1024

    private let reader = ZIPArchiveReader()

    @Test
    func readsDeflatedAndStoredConfigurations() throws {
        let archive = try ZIPFixture.archive([
            .file("Office.conf", "office configuration"),
            .storedFile("Prague.conf", "prague configuration"),
        ])

        #expect(
            try reader.configurationFiles(in: archive) == [
                ArchivedConfigurationFile(fileName: "Office.conf", contents: Data("office configuration".utf8)),
                ArchivedConfigurationFile(fileName: "Prague.conf", contents: Data("prague configuration".utf8)),
            ]
        )
    }

    @Test
    func findsConfigurationsInNestedFolders() throws {
        let archive = try ZIPFixture.archive([
            .directory("Exported/"),
            .directory("Exported/2026/"),
            .file("Exported/2026/Office.conf", "office configuration"),
        ])

        #expect(try reader.configurationFiles(in: archive).map(\.fileName) == ["Office.conf"])
    }

    @Test
    func skipsMetadataLinksAndOtherFiles() throws {
        let archive = try ZIPFixture.archive([
            .file("__MACOSX/._Office.conf", "resource fork"),
            .file(".DS_Store", "finder state"),
            .file("README.txt", "notes"),
            .symlink("Link.conf", to: "/etc/hosts"),
            .file("Office.conf", "office configuration"),
        ])

        #expect(try reader.configurationFiles(in: archive).map(\.fileName) == ["Office.conf"])
    }

    @Test
    func readsAnArchiveCompressedByFinder() throws {
        #expect(
            try reader.configurationFiles(in: FinderArchiveFixture.data()) == [
                ArchivedConfigurationFile(
                    fileName: "Office.conf",
                    contents: Data("[Interface]\nAddress = 10.0.0.2/32\n".utf8)
                ),
                ArchivedConfigurationFile(
                    fileName: "Prague.conf",
                    contents: Data("[Interface]\nAddress = 10.0.0.3/32\n".utf8)
                ),
            ]
        )
    }

    @Test
    func rejectsDataThatIsNotAZIPArchive() {
        #expect(throws: ArchiveReadingError.unreadableArchive) {
            try reader.configurationFiles(in: Data("[Interface]\nAddress = 10.0.0.2/32\n".utf8))
        }
    }

    @Test
    func rejectsContentsThatDoNotMatchTheirChecksum() throws {
        let archive = try ZIPFixture.archive([.storedFile("Office.conf", "office configuration")])

        #expect(throws: ArchiveReadingError.unreadableArchive) {
            try reader.configurationFiles(in: ZIPFixture.corruptingFirstContentByte(ofOnlyStoredEntryIn: archive))
        }
    }

    @Test
    func acceptsConfigurationFilesUpToTheLimit() throws {
        let archive = try ZIPFixture.archive(Self.configurations(count: 100))

        #expect(try reader.configurationFiles(in: archive).count == 100)
    }

    @Test
    func rejectsMoreConfigurationFilesThanTheLimit() throws {
        let archive = try ZIPFixture.archive(Self.configurations(count: 101))

        #expect(throws: ArchiveReadingError.tooManyConfigurationFiles(limit: 100)) {
            try reader.configurationFiles(in: archive)
        }
    }

    @Test
    func rejectsConfigurationsLargerThanTheSizeLimitInTotal() throws {
        let archive = try ZIPFixture.archive([
            .file("Office.conf", repeating: 0x20, count: 6 * 1024 * 1024),
            .file("Prague.conf", repeating: 0x20, count: 6 * 1024 * 1024),
        ])

        #expect(throws: ArchiveReadingError.configurationsTooLarge(limitInBytes: Self.sizeLimit)) {
            try reader.configurationFiles(in: archive)
        }
    }

    @Test
    func stopsInflatingAnEntryThatUnderstatesItsSize() throws {
        let archive = try ZIPFixture.archive([.file("Office.conf", repeating: 0x20, count: 11 * 1024 * 1024)])
        let understatingArchive = ZIPFixture.understatingUncompressedSize(ofOnlyEntryIn: archive, as: 1024)

        #expect(throws: ArchiveReadingError.configurationsTooLarge(limitInBytes: Self.sizeLimit)) {
            try reader.configurationFiles(in: understatingArchive)
        }
    }

    @Test
    func ignoresTheSizeOfSkippedFiles() throws {
        let archive = try ZIPFixture.archive([
            .file("Video.mov", repeating: 0, count: 11 * 1024 * 1024),
            .file("Office.conf", "office configuration"),
        ])

        #expect(try reader.configurationFiles(in: archive).map(\.fileName) == ["Office.conf"])
    }

    private static func configurations(count: Int) -> [ZIPFixtureEntry] {
        (1...count).map { index in .file("Tunnel \(index).conf", "configuration \(index)") }
    }
}
