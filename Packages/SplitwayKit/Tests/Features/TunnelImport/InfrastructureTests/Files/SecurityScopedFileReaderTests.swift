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

    @Test(arguments: ["tmp/com.example.splitway-Inbox", "Documents/Inbox"])
    func removesACopyTheSystemPutInTheInboxAfterReadingIt(inbox: String) async throws {
        let copy = try file(named: "Office.conf", in: inbox, contents: Data("office configuration".utf8))

        let batch = await inboxReader(in: directory).read([copy])

        #expect(batch.payloads == [.file(name: "Office.conf", contents: Data("office configuration".utf8))])
        #expect(!FileManager.default.fileExists(atPath: copy.path(percentEncoded: false)))
    }

    @Test
    func removesACopyFromTheInboxItCannotImport() async throws {
        let largeCopy = try file(
            named: "Large.conf",
            in: "Documents/Inbox",
            contents: Data(count: ImportFileBatch.maximumFileByteCount + 1)
        )

        let batch = await inboxReader(in: directory).read([largeCopy])

        #expect(batch.unreadableFileNames == ["Large.conf"])
        #expect(!FileManager.default.fileExists(atPath: largeCopy.path(percentEncoded: false)))
    }

    @Test(arguments: ["Documents", "tmp", "tmp/Inbox-notes", "Documents/Inbox/Nested"])
    func keepsAFileOutsideTheInbox(folder: String) async throws {
        let file = try file(named: "Office.conf", in: folder, contents: Data("office configuration".utf8))

        _ = await inboxReader(in: directory).read([file])

        #expect(FileManager.default.fileExists(atPath: file.path(percentEncoded: false)))
    }

    @Test
    func keepsTheInboxOfAnotherContainer() async throws {
        let foreignCopy = try file(
            named: "Office.conf",
            in: "Other/tmp/com.example.splitway-Inbox",
            contents: Data("office configuration".utf8)
        )
        let container = directory.appending(path: "Splitway")

        _ = await inboxReader(in: container).read([foreignCopy])

        #expect(FileManager.default.fileExists(atPath: foreignCopy.path(percentEncoded: false)))
    }

    private func inboxReader(in container: URL) -> SecurityScopedFileReader {
        SecurityScopedFileReader(inbox: ReceivedFileInbox(applicationContainer: container))
    }

    private func file(named name: String, contents: Data) throws -> URL {
        let url = directory.appending(path: name)
        try contents.write(to: url)
        return url
    }

    private func file(named name: String, in folder: String, contents: Data) throws -> URL {
        let folderURL = directory.appending(path: folder)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let url = folderURL.appending(path: name)
        try contents.write(to: url)
        return url
    }
}
