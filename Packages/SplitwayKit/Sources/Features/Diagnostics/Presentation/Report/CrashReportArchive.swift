import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct CrashReportArchive: Transferable {
    let data: Data
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .zip) { archive in
            archive.data
        }
        .suggestedFileName { archive in archive.fileName }
    }
}
