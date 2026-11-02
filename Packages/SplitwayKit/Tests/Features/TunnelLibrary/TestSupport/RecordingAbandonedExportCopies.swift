import Foundation
import TunnelLibrary

public actor RecordingAbandonedExportCopies: AbandonedExportCopies {
    public private(set) var removedContents: [Data] = []

    public init() {}

    public func removeCopies(of contents: Data) async {
        removedContents.append(contents)
    }
}
