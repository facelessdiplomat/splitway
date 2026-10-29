import Diagnostics
import DiagnosticsInfrastructure
import Foundation
import Testing
import ZIPFoundation

@Suite
struct ZIPCrashReportArchiverTests {
    @Test
    func archivesEveryFileOfTheBundle() throws {
        let files = [
            CrashReportFile(name: "info.txt", contents: Data("Splitway 0.1.0 (1)\n".utf8)),
            CrashReportFile(name: "log.txt", contents: Data("2026-10-29T10:15:00Z info application: Started\n".utf8)),
        ]
        let bundle = CrashReportBundle(
            files: files, includedLogEntryCount: 1, includedReportCount: 0, isTruncated: false)

        let data = try ZIPCrashReportArchiver().archive(bundle)

        let archive = try Archive(data: data, accessMode: .read)
        var unpacked: [CrashReportFile] = []
        for entry in archive {
            var contents = Data()
            _ = try archive.extract(entry) { chunk in contents.append(chunk) }
            unpacked.append(CrashReportFile(name: entry.path, contents: contents))
        }
        #expect(unpacked == files)
    }
}
