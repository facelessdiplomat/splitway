import Foundation
import TunnelLibrary

public struct FindShortcutTunnelsUseCase: Sendable {
    private let records: any TunnelRecordRepository

    public init(records: any TunnelRecordRepository) {
        self.records = records
    }

    public func all() async throws(TunnelShortcutError) -> [TunnelRecord] {
        do {
            return try await records.loadRecords()
        } catch {
            throw .libraryUnavailable
        }
    }

    public func tunnels(matching text: String) async throws(TunnelShortcutError) -> [TunnelRecord] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let tunnels = try await all()
        guard !query.isEmpty else { return tunnels }
        return tunnels.filter { tunnel in tunnel.name.description.localizedStandardContains(query) }
    }

    public func tunnels(
        identifiedBy identifiers: [TunnelIdentifier]
    ) async throws(TunnelShortcutError) -> [TunnelRecord] {
        let tunnelsByIdentifier = Dictionary(
            try await all().map { tunnel in (tunnel.id, tunnel) },
            uniquingKeysWith: { first, _ in first }
        )
        return identifiers.compactMap { identifier in tunnelsByIdentifier[identifier] }
    }
}
