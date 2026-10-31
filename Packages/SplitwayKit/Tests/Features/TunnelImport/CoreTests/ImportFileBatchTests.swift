import Foundation
import Testing
import TunnelImport

@Suite
struct ImportFileBatchTests {
    @Test
    func appendsPayloadsAndUnreadableNamesAfterItsOwn() {
        let first = ImportFileBatch(
            payloads: [.file(name: "Office.conf", contents: Data("A".utf8))],
            unreadableFileNames: ["Locked.conf"]
        )
        let second = ImportFileBatch(
            payloads: [.file(name: "Home.conf", contents: Data("B".utf8))],
            unreadableFileNames: ["Broken.conf"]
        )

        let combined = first.appending(second)

        #expect(
            combined
                == ImportFileBatch(
                    payloads: [
                        .file(name: "Office.conf", contents: Data("A".utf8)),
                        .file(name: "Home.conf", contents: Data("B".utf8)),
                    ],
                    unreadableFileNames: ["Locked.conf", "Broken.conf"]
                )
        )
    }

    @Test
    func emptyBatchHasNothingToImport() {
        #expect(ImportFileBatch.empty.payloads.isEmpty)
        #expect(ImportFileBatch.empty.unreadableFileNames.isEmpty)
    }
}
