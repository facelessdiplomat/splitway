import AppKit
import Settings

public struct WorkspaceApplicationRemoval: ApplicationRemoval {
    private let applicationURL: URL

    public init(applicationURL: URL) {
        self.applicationURL = applicationURL
    }

    public func showInFinderAndQuit() async {
        let applicationURL = applicationURL
        await MainActor.run {
            NSWorkspace.shared.activateFileViewerSelecting([applicationURL])
        }
        await quit()
    }

    public func quit() async {
        await MainActor.run {
            NSApplication.shared.terminate(nil)
        }
    }
}
