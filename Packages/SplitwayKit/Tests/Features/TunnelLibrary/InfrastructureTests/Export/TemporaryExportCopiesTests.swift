import Foundation
import Testing
import TunnelLibraryInfrastructure

@Suite
final class TemporaryExportCopiesTests {
    private let directory: URL
    private let exported = Data("[Interface]\nPrivateKey = exported\n".utf8)

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appending(path: "TemporaryExportCopiesTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func removesTheCopyAndTheFolderTheSystemMadeForIt() async throws {
        let folder = directory.appending(path: UUID().uuidString)
        let copy = try write(exported, to: folder.appending(path: "Office.conf"))

        await TemporaryExportCopies(directory: directory).removeCopies(of: exported)

        #expect(!exists(copy))
        #expect(!exists(folder))
        #expect(exists(directory))
    }

    @Test
    func removesACopyLyingInTheDirectoryItself() async throws {
        let copy = try write(exported, to: directory.appending(path: "Office.conf"))

        await TemporaryExportCopies(directory: directory).removeCopies(of: exported)

        #expect(!exists(copy))
        #expect(exists(directory))
    }

    @Test
    func keepsFilesWithOtherContents() async throws {
        let sameSize = try write(
            Data(repeating: 0x41, count: exported.count),
            to: directory.appending(path: "Other/Office.conf")
        )
        let otherSize = try write(Data("tunnels".utf8), to: directory.appending(path: "Storage/tunnels.json"))

        await TemporaryExportCopies(directory: directory).removeCopies(of: exported)

        #expect(exists(sameSize))
        #expect(exists(otherSize))
    }

    @Test
    func keepsOtherFilesNextToACopy() async throws {
        let folder = directory.appending(path: "Storage")
        let copy = try write(exported, to: folder.appending(path: "Office.conf"))
        let neighbour = try write(Data("tunnels".utf8), to: folder.appending(path: "tunnels.json"))

        await TemporaryExportCopies(directory: directory).removeCopies(of: exported)

        #expect(!exists(copy))
        #expect(exists(neighbour))
    }

    private func write(_ contents: Data, to file: URL) throws -> URL {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: file)
        return file
    }

    private func exists(_ item: URL) -> Bool {
        FileManager.default.fileExists(atPath: item.path(percentEncoded: false))
    }
}
