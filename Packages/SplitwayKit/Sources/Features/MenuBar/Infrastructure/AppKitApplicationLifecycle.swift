import AppKit
import MenuBar

public struct AppKitApplicationLifecycle: ApplicationLifecycle {
    public init() {}

    @MainActor
    public func activate() {
        NSApplication.shared.activate()
    }

    @MainActor
    public func terminate() {
        NSApplication.shared.terminate(nil)
    }
}
