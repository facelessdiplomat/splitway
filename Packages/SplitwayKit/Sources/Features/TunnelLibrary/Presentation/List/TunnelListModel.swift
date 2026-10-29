import Foundation
import Observation
import TunnelConnection
import TunnelLibrary

@MainActor
@Observable
public final class TunnelListModel {
    public private(set) var rows: [TunnelRow] = []
    public private(set) var pendingDeletion: TunnelDeletionRequest?
    public private(set) var alert: TunnelListAlert?
    private var hasLoaded = false
    private var entries: [TunnelLibraryEntry] = []
    private var slot = SlotState.empty

    private let library: TunnelLibraryActions
    private let connection: TunnelConnectionActions

    public init(library: TunnelLibraryActions, connection: TunnelConnectionActions) {
        self.library = library
        self.connection = connection
    }

    public var isEmpty: Bool {
        hasLoaded && rows.isEmpty
    }

    public func row(withID id: TunnelIdentifier) -> TunnelRow? {
        rows.first { row in row.id == id }
    }

    public func deletionRequest(for id: TunnelIdentifier) -> TunnelDeletionRequest? {
        pendingDeletion?.tunnelID == id ? pendingDeletion : nil
    }

    public func tunnel(withID id: TunnelIdentifier) -> Tunnel? {
        for case .readable(let tunnel) in entries where tunnel.id == id {
            return tunnel
        }
        return nil
    }

    public func load() async {
        do {
            entries = try await library.loadTunnels.execute().entries
        } catch {
            alert = .library(error)
        }
        hasLoaded = true
        rebuildRows()
    }

    public func observeConnection() async {
        for await state in connection.observeConnection.execute() {
            apply(state)
        }
    }

    public func apply(_ state: SlotState) {
        slot = state
        rebuildRows()
    }

    public func toggleConnection(of row: TunnelRow) async {
        guard !row.isConnectionActive else {
            await connection.deactivateTunnel.execute()
            return
        }
        guard let tunnel = tunnel(withID: row.id) else { return }
        do {
            try await connection.activateTunnel.execute(tunnel)
        } catch {
            alert = .connection(error)
        }
    }

    public func requestDeletion(of row: TunnelRow) {
        pendingDeletion = TunnelDeletionRequest(
            tunnelID: row.id,
            tunnelName: row.name,
            disconnectsTunnel: row.isConnectionActive
        )
    }

    public func confirmDeletion(of request: TunnelDeletionRequest) async {
        pendingDeletion = nil
        do {
            try await library.deleteTunnel.execute(id: request.tunnelID)
        } catch {
            alert = .library(error)
        }
        await load()
    }

    public func cancelDeletion() {
        pendingDeletion = nil
    }

    public func duplicate(_ row: TunnelRow) async {
        do {
            _ = try await library.duplicateTunnel.execute(id: row.id)
        } catch {
            alert = .library(error)
        }
        await load()
    }

    public func move(fromOffsets source: IndexSet, toOffset destination: Int) async {
        entries.move(fromOffsets: source, toOffset: destination)
        rebuildRows()
        do {
            try await library.reorderTunnels.execute(order: entries.map(\.id))
        } catch {
            alert = .library(error)
            await load()
        }
    }

    public func dismissAlert() {
        alert = nil
    }

    private func rebuildRows() {
        rows = entries.map { entry in entry.row(in: slot) }
    }
}
