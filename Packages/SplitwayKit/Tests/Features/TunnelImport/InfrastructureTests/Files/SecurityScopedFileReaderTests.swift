import Foundation
import Testing
import TunnelImport
import TunnelImportInfrastructure

@Suite
final class SecurityScopedFileReaderTests {
    private let directory: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appending(path: "SecurityScopedFileReaderTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func readsEachFileUnderItsName() async throws {
        let office = try file(named: "Office.conf", contents: Data("office configuration".utf8))
        let archive = try file(named: "export.zip", contents: Data([0x50, 0x4B, 0x03, 0x04]))

        let batch = await SecurityScopedFileReader().read([office, archive])

        #expect(
            batch.payloads == [
                .file(name: "Office.conf", contents: Data("office configuration".utf8)),
                .file(name: "export.zip", contents: Data([0x50, 0x4B, 0x03, 0x04])),
            ]
        )
        #expect(batch.unreadableFileNames.isEmpty)
    }

    @Test
    func reportsAFileThatDoesNotExist() async {
        let missing = directory.appending(path: "Missing.conf")

        let batch = await SecurityScopedFileReader().read([missing])

        #expect(batch.payloads.isEmpty)
        #expect(batch.unreadableFileNames == ["Missing.conf"])
    }

    @Test
    func refusesAFileLargerThanTheLimit() async throws {
        let large = try file(named: "Large.conf", contents: Data(count: ImportFileBatch.maximumFileByteCount + 1))

        let batch = await SecurityScopedFileReader().read([large])

        #expect(batch.payloads.isEmpty)
        #expect(batch.unreadableFileNames == ["Large.conf"])
    }

    private func file(named name: String, contents: Data) throws -> URL {
        let url = directory.appending(path: name)
        try contents.write(to: url)
        return url
    }
}
