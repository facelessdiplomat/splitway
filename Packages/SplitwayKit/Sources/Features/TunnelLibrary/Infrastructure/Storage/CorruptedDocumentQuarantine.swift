import Foundation
import SharedKernel

struct CorruptedDocumentQuarantine: Sendable {
    private static let timestampStyle = Date.ISO8601FormatStyle(
        dateSeparator: .omitted,
        dateTimeSeparator: .standard,
        timeSeparator: .omitted,
        timeZoneSeparator: .omitted,
        includingFractionalSeconds: false,
        timeZone: .gmt
    )

    private let clock: any WallClock

    init(clock: any WallClock) {
        self.clock = clock
    }

    func moveAside(_ documentURL: URL) {
        try? FileManager.default.moveItem(at: documentURL, to: quarantineURL(for: documentURL))
    }

    private func quarantineURL(for documentURL: URL) -> URL {
        let baseName = documentURL.deletingPathExtension().lastPathComponent
        let timestamp = clock.now().formatted(Self.timestampStyle)
        let quarantineFileName = "\(baseName).corrupted-\(timestamp).\(documentURL.pathExtension)"
        return documentURL.deletingLastPathComponent().appending(path: quarantineFileName)
    }
}
