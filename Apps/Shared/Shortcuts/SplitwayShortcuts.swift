import AppIntents

struct SplitwayShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleTunnelIntent(),
            phrases: [
                "Toggle \(\.$tunnel) in \(.applicationName)",
                "Toggle a tunnel in \(.applicationName)",
            ],
            shortTitle: "Toggle Tunnel",
            systemImageName: "power"
        )
        AppShortcut(
            intent: ConnectTunnelIntent(),
            phrases: [
                "Connect \(\.$tunnel) in \(.applicationName)",
                "Connect a tunnel in \(.applicationName)",
            ],
            shortTitle: "Connect Tunnel",
            systemImageName: "network"
        )
        AppShortcut(
            intent: DisconnectTunnelIntent(),
            phrases: [
                "Disconnect \(\.$tunnel) in \(.applicationName)",
                "Disconnect a tunnel in \(.applicationName)",
            ],
            shortTitle: "Disconnect Tunnel",
            systemImageName: "network.slash"
        )
    }
}
