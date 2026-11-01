#if os(macOS)
    import AppKit
    import MenuBar

    @MainActor
    public final class AppKitDockPresence {
        private static let windowEvents: [Notification.Name] = [
            NSWindow.didBecomeKeyNotification,
            NSWindow.didMiniaturizeNotification,
            NSWindow.didDeminiaturizeNotification,
            NSWindow.willCloseNotification,
        ]

        private var observers: [any NSObjectProtocol] = []

        public init() {}

        isolated deinit {
            for observer in observers {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        public func start() {
            observers = Self.windowEvents.map { event in
                NotificationCenter.default.addObserver(forName: event, object: nil, queue: .main) { [weak self] note in
                    let closingWindow = event == NSWindow.willCloseNotification ? Self.identifier(of: note) : nil
                    MainActor.assumeIsolated {
                        self?.applyPresence(closingWindow: closingWindow)
                    }
                }
            }
        }

        private nonisolated static func identifier(of notification: Notification) -> ObjectIdentifier? {
            (notification.object as? NSWindow).map(ObjectIdentifier.init)
        }

        private func applyPresence(closingWindow: ObjectIdentifier?) {
            let application = NSApplication.shared
            let windows = application.windows.map { window in
                AppWindowState(
                    isTitled: window.styleMask.contains(.titled),
                    isVisible: window.isVisible,
                    isMinimized: window.isMiniaturized,
                    isClosing: ObjectIdentifier(window) == closingWindow
                )
            }
            let policy: NSApplication.ActivationPolicy =
                DockVisibilityPolicy.presence(for: windows) == .shown ? .regular : .accessory
            guard application.activationPolicy() != policy else { return }
            application.setActivationPolicy(policy)
            if policy == .regular {
                application.activate()
            }
        }
    }
#endif
