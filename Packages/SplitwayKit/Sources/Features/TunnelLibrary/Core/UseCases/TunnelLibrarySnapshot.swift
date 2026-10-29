public struct TunnelLibrarySnapshot: Sendable, Hashable {
    public let entries: [TunnelLibraryEntry]

    public var tunnels: [Tunnel] {
        entries.compactMap { entry in
            if case .readable(let tunnel) = entry { tunnel } else { nil }
        }
    }

    public var unreadableRecords: [TunnelRecord] {
        entries.compactMap { entry in
            if case .unreadable(let record) = entry { record } else { nil }
        }
    }
}
