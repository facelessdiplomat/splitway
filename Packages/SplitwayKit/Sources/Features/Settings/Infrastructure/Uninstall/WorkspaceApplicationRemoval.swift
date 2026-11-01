#if os(macOS)
    import AppKit
    import Settings

    public struct WorkspaceApplicationRemoval: ApplicationRemoval {
        private let applicationURL: URL

        public init(applicationURL: URL) {
            self.applicationURL = applicationURL
        }

        public func moveToTrashAndQuit() async throws(ApplicationRemovalError) {
            guard await Self.recycle(applicationURL) else { throw .notMovedToTrash }
            await quit()
        }

        public func quit() async {
            await MainActor.run {
                NSApplication.shared.terminate(nil)
            }
        }

        @MainActor
        private static func recycle(_ url: URL) async -> Bool {
            (try? await NSWorkspace.shared.recycle([url])) != nil
        }
    }
#endif
