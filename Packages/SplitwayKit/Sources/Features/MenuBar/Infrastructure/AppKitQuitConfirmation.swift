#if os(macOS)
    import AppKit
    import MenuBar

    public struct AppKitQuitConfirmation: QuitConfirmation {
        public init() {}

        @MainActor
        public func decision(forActiveTunnelNamed name: String) async -> QuitDecision {
            let alert = NSAlert()
            alert.messageText = String(localized: "Disconnect “\(name)” before quitting?", bundle: .module)
            alert.informativeText = String(localized: "The tunnel keeps working after Splitway quits.", bundle: .module)
            alert.addButton(withTitle: String(localized: "Disconnect and Quit", bundle: .module))
            alert.addButton(withTitle: String(localized: "Quit", bundle: .module))
            alert.addButton(withTitle: String(localized: "Cancel", bundle: .module))
            NSApplication.shared.activate()
            switch alert.runModal() {
            case .alertFirstButtonReturn: return .disconnectAndQuit
            case .alertSecondButtonReturn: return .quitKeepingConnection
            default: return .stay
            }
        }
    }
#endif
