import CoreTransferable
import Foundation
import TunnelImport
import UniformTypeIdentifiers

public struct DroppedImportFile: Transferable, Sendable {
    public let payload: ImportPayload

    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .data) { received in
            let batch = await SecurityScopedFileReader().read([received.file])
            guard let payload = batch.payloads.first else { throw UnreadableDroppedFile() }
            return DroppedImportFile(payload: payload)
        }
    }
}
