import Diagnostics

public actor InMemoryLogHistory: LogHistory {
    private var storedEntries: [LogEntry]
    private let isAvailable: Bool
    public private(set) var readCount = 0
    private var readWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    public init(entries: [LogEntry] = [], isAvailable: Bool = true) {
        storedEntries = entries
        self.isAvailable = isAvailable
    }

    public func entries() throws(LogStoreError) -> [LogEntry] {
        readCount += 1
        let satisfied = readWaiters.filter { waiter in waiter.count <= readCount }
        readWaiters.removeAll { waiter in waiter.count <= readCount }
        for waiter in satisfied {
            waiter.continuation.resume()
        }
        guard isAvailable else { throw .unavailable }
        return storedEntries
    }

    public func removeAll() throws(LogStoreError) {
        guard isAvailable else { throw .unavailable }
        storedEntries.removeAll()
    }

    public func append(_ entry: LogEntry) {
        storedEntries.append(entry)
    }

    public func waitForReads(_ count: Int) async {
        guard readCount < count else { return }
        await withCheckedContinuation { continuation in readWaiters.append((count, continuation)) }
    }
}
