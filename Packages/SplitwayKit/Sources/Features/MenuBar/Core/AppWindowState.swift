public struct AppWindowState: Sendable, Equatable {
    public let isTitled: Bool
    public let isVisible: Bool
    public let isMinimized: Bool
    public let isClosing: Bool

    public init(isTitled: Bool, isVisible: Bool, isMinimized: Bool, isClosing: Bool) {
        self.isTitled = isTitled
        self.isVisible = isVisible
        self.isMinimized = isMinimized
        self.isClosing = isClosing
    }

    var keepsTheApplicationInTheDock: Bool {
        isTitled && !isClosing && (isVisible || isMinimized)
    }
}
