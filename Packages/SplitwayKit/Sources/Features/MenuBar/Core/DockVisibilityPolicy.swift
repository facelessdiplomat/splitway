public enum DockVisibilityPolicy {
    public static func presence(for windows: [AppWindowState]) -> DockPresence {
        windows.contains(where: \.keepsTheApplicationInTheDock) ? .shown : .hidden
    }
}
