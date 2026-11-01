import MenuBar
import Testing

@Suite
struct DockVisibilityPolicyTests {
    private static let openWindow = AppWindowState(
        isTitled: true,
        isVisible: true,
        isMinimized: false,
        isClosing: false
    )

    @Test
    func showsTheIconWhileAWindowIsOpen() {
        #expect(DockVisibilityPolicy.presence(for: [Self.openWindow]) == .shown)
    }

    @Test
    func keepsTheIconForAMinimizedWindowSoItCanBeRestored() {
        let minimized = AppWindowState(isTitled: true, isVisible: false, isMinimized: true, isClosing: false)

        #expect(DockVisibilityPolicy.presence(for: [minimized]) == .shown)
    }

    @Test
    func hidesTheIconWhenEveryWindowIsClosed() {
        let hidden = AppWindowState(isTitled: true, isVisible: false, isMinimized: false, isClosing: false)

        #expect(DockVisibilityPolicy.presence(for: []) == .hidden)
        #expect(DockVisibilityPolicy.presence(for: [hidden]) == .hidden)
    }

    @Test
    func ignoresTheMenuBarWindows() {
        let statusItem = AppWindowState(isTitled: false, isVisible: true, isMinimized: false, isClosing: false)

        #expect(DockVisibilityPolicy.presence(for: [statusItem]) == .hidden)
    }

    @Test
    func hidesTheIconWhenTheLastWindowCloses() {
        let closing = AppWindowState(isTitled: true, isVisible: true, isMinimized: false, isClosing: true)

        #expect(DockVisibilityPolicy.presence(for: [closing]) == .hidden)
        #expect(DockVisibilityPolicy.presence(for: [closing, Self.openWindow]) == .shown)
    }
}
