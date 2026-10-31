import MenuBar
import Observation
import TunnelLibraryPresentation

@MainActor
@Observable
public final class MenuBarModel {
    public private(set) var isMainWindowRequested = false

    private let tunnels: TunnelListModel
    private let quitConfirmation: any QuitConfirmation
    private let lifecycle: any ApplicationLifecycle

    public init(tunnels: TunnelListModel, quitConfirmation: any QuitConfirmation, lifecycle: any ApplicationLifecycle) {
        self.tunnels = tunnels
        self.quitConfirmation = quitConfirmation
        self.lifecycle = lifecycle
    }

    public var icon: MenuBarIcon {
        MenuBarIcon(statuses: tunnels.rows.map(\.status))
    }

    public var items: [MenuBarTunnel] {
        tunnels.rows.map(MenuBarTunnel.init(row:))
    }

    public var activeTunnel: TunnelRow? {
        tunnels.rows.first { row in row.isConnectionActive }
    }

    public var headlineTunnel: TunnelRow? {
        activeTunnel ?? tunnels.rows.first { row in row.status.failure != nil || row.status == .disconnecting }
    }

    public var hasNoTunnels: Bool {
        tunnels.isEmpty
    }

    public func start() async {
        await tunnels.load()
        await tunnels.observeConnection()
    }

    public func select(_ tunnel: MenuBarTunnel) async {
        guard let row = tunnels.row(withID: tunnel.id) else { return }
        await tunnels.toggleConnection(of: row)
        if tunnels.tunnelAwaitingSystemPrompt == row.id {
            requestMainWindow()
        }
    }

    public func requestMainWindow() {
        isMainWindowRequested = true
        lifecycle.activate()
    }

    public func mainWindowShown() {
        isMainWindowRequested = false
    }

    public func quit() async {
        guard let active = activeTunnel else {
            lifecycle.terminate()
            return
        }
        switch await quitConfirmation.decision(forActiveTunnelNamed: active.name) {
        case .disconnectAndQuit:
            await tunnels.toggleConnection(of: active)
            lifecycle.terminate()
        case .quitKeepingConnection:
            lifecycle.terminate()
        case .stay:
            break
        }
    }
}
