struct LeastRecentlyUsedCache<Key: Hashable & Sendable, Value: Sendable>: Sendable {
    private struct Entry: Sendable {
        let value: Value
        var lastUse: UInt64
    }

    private let capacity: Int
    private var entries: [Key: Entry] = [:]
    private var useCount: UInt64 = 0

    init(capacity: Int) {
        self.capacity = capacity
    }

    mutating func value(for key: Key) -> Value? {
        guard let entry = entries[key] else { return nil }
        useCount += 1
        entries[key]?.lastUse = useCount
        return entry.value
    }

    mutating func insert(_ value: Value, for key: Key) {
        useCount += 1
        entries[key] = Entry(value: value, lastUse: useCount)
        guard entries.count > capacity,
            let leastRecent = entries.min(by: { first, second in first.value.lastUse < second.value.lastUse })
        else { return }
        entries[leastRecent.key] = nil
    }
}
