import AppIntents
import Foundation
import Shortcuts
import TunnelLibrary

struct TunnelEntityQuery: EntityStringQuery {
    @Dependency
    private var shortcuts: TunnelShortcutActions

    func entities(for identifiers: [TunnelEntity.ID]) async throws -> [TunnelEntity] {
        do {
            let records = try await shortcuts.findTunnels.tunnels(identifiedBy: identifiers.map(TunnelIdentifier.init))
            return records.map(TunnelEntity.init(record:))
        } catch {
            throw TunnelShortcutFailure(error)
        }
    }

    func entities(matching string: String) async throws -> [TunnelEntity] {
        do {
            return try await shortcuts.findTunnels.tunnels(matching: string).map(TunnelEntity.init(record:))
        } catch {
            throw TunnelShortcutFailure(error)
        }
    }

    func suggestedEntities() async throws -> [TunnelEntity] {
        do {
            return try await shortcuts.findTunnels.all().map(TunnelEntity.init(record:))
        } catch {
            throw TunnelShortcutFailure(error)
        }
    }
}
