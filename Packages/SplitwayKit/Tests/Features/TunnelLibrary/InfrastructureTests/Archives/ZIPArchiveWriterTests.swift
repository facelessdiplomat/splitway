import Foundation
import Testing
import TunnelLibrary
import TunnelLibraryInfrastructure
import ZIPFoundation

@Suite
struct ZIPArchiveWriterTests {
    private let writer = ZIPArchiveWriter()

    @Test
    func writesEveryFileAsAnEntry() throws {
        let archive = try readableArchive(of: [
            ExportedConfigurationFile(fileName: "Office.conf", contents: "office configuration"),
            ExportedConfigurationFile(fileName: "Prague.conf", contents: "prague configuration"),
        ])

        #expect(archive.map(\.path) == ["Office.conf", "Prague.conf"])
        #expect(try Self.text(of: "Office.conf", in: archive) == "office configuration")
        #expect(try Self.text(of: "Prague.conf", in: archive) == "prague configuration")
    }

    @Test
    func keepsNonASCIIFileNames() throws {
        let archive = try readableArchive(of: [ExportedConfigurationFile(fileName: "Офис.conf", contents: "office")])

        #expect(archive.map(\.path) == ["Офис.conf"])
    }

    @Test
    func restrictsExtractedFilesToTheirOwner() throws {
        let archive = try readableArchive(of: [ExportedConfigurationFile(fileName: "Office.conf", contents: "office")])

        let entry = try #require(archive["Office.conf"])
        #expect(entry.fileAttributes[.posixPermissions] as? UInt16 == 0o600)
    }

    private func readableArchive(of files: [ExportedConfigurationFile]) throws -> Archive {
        try Archive(data: writer.archive(files), accessMode: .read)
    }

    private static func text(of path: String, in archive: Archive) throws -> String {
        let entry = try #require(archive[path])
        var contents = Data()
        _ = try archive.extract(entry) { chunk in contents.append(chunk) }
        return try #require(String(bytes: contents, encoding: .utf8))
    }
}
