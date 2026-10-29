import Foundation
import Testing
import TransparentProxy

@Suite
struct UDPAssociationTableTests {
    private static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
    private static let idleTimeout: TimeInterval = 300

    @Test
    func findsTheAssociationOfADestination() throws {
        var table = try Self.table(maximumAssociations: 4)

        _ = table.insert(1, for: "203.0.113.7:443", at: Self.start)

        #expect(table.association(for: "203.0.113.7:443") == 1)
        #expect(table.association(for: "203.0.113.8:443") == nil)
    }

    @Test
    func expiresAssociationsIdleForTheTimeout() throws {
        var table = try Self.table(maximumAssociations: 4)
        _ = table.insert(1, for: "203.0.113.7:443", at: Self.start)
        _ = table.insert(2, for: "203.0.113.8:443", at: Self.start.addingTimeInterval(60))

        let expired = table.removeExpired(at: Self.start.addingTimeInterval(Self.idleTimeout))

        #expect(expired == [1])
        #expect(table.association(for: "203.0.113.7:443") == nil)
        #expect(table.count == 1)
    }

    @Test
    func keepsAssociationsWithRecentActivity() throws {
        var table = try Self.table(maximumAssociations: 4)
        _ = table.insert(1, for: "203.0.113.7:443", at: Self.start)
        table.recordActivity(for: "203.0.113.7:443", at: Self.start.addingTimeInterval(Self.idleTimeout - 1))

        let expired = table.removeExpired(at: Self.start.addingTimeInterval(Self.idleTimeout))

        #expect(expired.isEmpty)
        #expect(table.association(for: "203.0.113.7:443") == 1)
    }

    @Test
    func evictsTheLeastRecentlyActiveAssociationWhenFull() throws {
        var table = try Self.table(maximumAssociations: 2)
        _ = table.insert(1, for: "203.0.113.7:443", at: Self.start)
        _ = table.insert(2, for: "203.0.113.8:443", at: Self.start.addingTimeInterval(1))
        table.recordActivity(for: "203.0.113.7:443", at: Self.start.addingTimeInterval(2))

        let evicted = table.insert(3, for: "203.0.113.9:443", at: Self.start.addingTimeInterval(3))

        #expect(evicted == 2)
        #expect(table.count == 2)
        #expect(table.association(for: "203.0.113.7:443") == 1)
    }

    @Test
    func replacesTheAssociationOfAKnownDestinationWithoutEvictingOthers() throws {
        var table = try Self.table(maximumAssociations: 2)
        _ = table.insert(1, for: "203.0.113.7:443", at: Self.start)
        _ = table.insert(2, for: "203.0.113.8:443", at: Self.start.addingTimeInterval(1))

        let replaced = table.insert(3, for: "203.0.113.7:443", at: Self.start.addingTimeInterval(2))

        #expect(replaced == 1)
        #expect(table.association(for: "203.0.113.7:443") == 3)
        #expect(table.association(for: "203.0.113.8:443") == 2)
    }

    @Test
    func removesAFailedAssociationAndEveryAssociationOnClose() throws {
        var table = try Self.table(maximumAssociations: 4)
        _ = table.insert(1, for: "203.0.113.7:443", at: Self.start)
        _ = table.insert(2, for: "203.0.113.8:443", at: Self.start)
        _ = table.insert(3, for: "203.0.113.9:443", at: Self.start)

        let failed = table.remove("203.0.113.7:443")
        let closed = table.removeAll()

        #expect(failed == 1)
        #expect(Set(closed) == [2, 3])
        #expect(table.isEmpty)
    }

    private static func table(maximumAssociations: Int) throws -> UDPAssociationTable<String, Int> {
        let policy = try UDPRelayPolicy(
            datagramBufferByteCount: UDPRelayPolicy.largestDatagramByteCount,
            idleTimeout: .seconds(idleTimeout),
            maximumAssociations: maximumAssociations
        )
        return UDPAssociationTable(policy: policy)
    }
}
