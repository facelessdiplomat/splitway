import Foundation

public struct UDPAssociationTable<Destination: Hashable & Sendable, Association: Sendable>: Sendable {
    private struct Entry: Sendable {
        let association: Association
        var lastActivity: Date
    }

    private let policy: UDPRelayPolicy
    private var entries: [Destination: Entry] = [:]

    public init(policy: UDPRelayPolicy) {
        self.policy = policy
    }

    public var count: Int {
        entries.count
    }

    public var isEmpty: Bool {
        entries.isEmpty
    }

    public func association(for destination: Destination) -> Association? {
        entries[destination]?.association
    }

    public mutating func recordActivity(for destination: Destination, at moment: Date) {
        entries[destination]?.lastActivity = moment
    }

    public mutating func insert(_ association: Association, for destination: Destination, at moment: Date)
        -> Association?
    {
        let departed = entries[destination]?.association ?? evictLeastRecentlyActiveWhenFull()
        entries[destination] = Entry(association: association, lastActivity: moment)
        return departed
    }

    public mutating func remove(_ destination: Destination) -> Association? {
        entries.removeValue(forKey: destination)?.association
    }

    public mutating func removeExpired(at moment: Date) -> [Association] {
        let expired = entries.filter { _, entry in
            Duration.seconds(moment.timeIntervalSince(entry.lastActivity)) >= policy.idleTimeout
        }
        for destination in expired.keys {
            entries[destination] = nil
        }
        return expired.values.map(\.association)
    }

    public mutating func removeAll() -> [Association] {
        defer { entries.removeAll() }
        return entries.values.map(\.association)
    }

    private mutating func evictLeastRecentlyActiveWhenFull() -> Association? {
        guard entries.count >= policy.maximumAssociations,
            let leastRecent = entries.min(by: { first, second in first.value.lastActivity < second.value.lastActivity })
        else { return nil }
        entries[leastRecent.key] = nil
        return leastRecent.value.association
    }
}
