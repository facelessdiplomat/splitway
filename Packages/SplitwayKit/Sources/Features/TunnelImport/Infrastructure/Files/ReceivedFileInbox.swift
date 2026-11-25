import Foundation

public struct ReceivedFileInbox: Sendable {
    private static let documentsFolderName = "Documents"
    private static let documentsInboxName = "Inbox"
    private static let temporaryFolderName = "tmp"
    private static let temporaryInboxSuffix = "-Inbox"

    private let applicationContainer: URL

    public init(applicationContainer: URL) {
        self.applicationContainer = applicationContainer
    }

    func contains(_ file: URL) -> Bool {
        let inbox = file.resolvingSymlinksInPath().deletingLastPathComponent()
        let inboxParent = inbox.deletingLastPathComponent().standardizedFileURL.pathComponents
        let container = applicationContainer.resolvingSymlinksInPath()
        let documents = container.appending(path: Self.documentsFolderName).standardizedFileURL.pathComponents
        let temporary = container.appending(path: Self.temporaryFolderName).standardizedFileURL.pathComponents
        let isDocumentsInbox = inboxParent == documents && inbox.lastPathComponent == Self.documentsInboxName
        let isTemporaryInbox = inboxParent == temporary && inbox.lastPathComponent.hasSuffix(Self.temporaryInboxSuffix)
        return isDocumentsInbox || isTemporaryInbox
    }
}
