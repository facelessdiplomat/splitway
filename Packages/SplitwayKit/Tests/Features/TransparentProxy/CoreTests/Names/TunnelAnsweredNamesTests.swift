import DNSProxy
import DNSProxyTestSupport
import Foundation
import SharedKernel
import Testing
import TransparentProxy

@Suite
struct TunnelAnsweredNamesTests {
    static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

    @Test
    func remembersTheAddressesOfAnAnswerForItsTimeToLive() throws {
        let names = TunnelAnsweredNames(policy: try Self.policy())
        let name = try DomainName("example.com")

        names.record(try Self.answers("example.com", [("192.0.2.10", 300)]), at: Self.start)

        #expect(names.addresses(for: name, at: Self.start.addingTimeInterval(299)) == [try IPAddress("192.0.2.10")])
        #expect(names.addresses(for: name, at: Self.start.addingTimeInterval(300)).isEmpty)
    }

    @Test
    func keepsAShortLivedAnswerForTheMinimumRetention() throws {
        let names = TunnelAnsweredNames(policy: try Self.policy())
        let name = try DomainName("example.com")

        names.record(try Self.answers("example.com", [("192.0.2.10", 5)]), at: Self.start)

        #expect(names.addresses(for: name, at: Self.start.addingTimeInterval(59)) == [try IPAddress("192.0.2.10")])
        #expect(names.addresses(for: name, at: Self.start.addingTimeInterval(60)).isEmpty)
    }

    @Test
    func forgetsALongLivedAnswerAfterTheMaximumRetention() throws {
        let names = TunnelAnsweredNames(policy: try Self.policy())
        let name = try DomainName("example.com")

        names.record(try Self.answers("example.com", [("192.0.2.10", 86_400)]), at: Self.start)

        #expect(names.addresses(for: name, at: Self.start.addingTimeInterval(599)) == [try IPAddress("192.0.2.10")])
        #expect(names.addresses(for: name, at: Self.start.addingTimeInterval(600)).isEmpty)
    }

    @Test
    func remembersItsOwnLookupForTheMinimumRetention() throws {
        let names = TunnelAnsweredNames(policy: try Self.policy())
        let name = try DomainName("example.com")

        names.record([try IPAddress("192.0.2.10")], for: name, at: Self.start)

        #expect(names.addresses(for: name, at: Self.start.addingTimeInterval(59)) == [try IPAddress("192.0.2.10")])
        #expect(names.addresses(for: name, at: Self.start.addingTimeInterval(60)).isEmpty)
    }

    @Test
    func addsTheAddressesOfALaterAnswer() throws {
        let names = TunnelAnsweredNames(policy: try Self.policy())
        let name = try DomainName("example.com")

        names.record(try Self.answers("example.com", [("192.0.2.10", 300)]), at: Self.start)
        names.record(try Self.answers("example.com", [("192.0.2.11", 300)]), at: Self.start.addingTimeInterval(10))

        #expect(
            names.addresses(for: name, at: Self.start.addingTimeInterval(20))
                == [try IPAddress("192.0.2.10"), try IPAddress("192.0.2.11")])
    }

    @Test
    func forgetsTheLeastRecentlyUsedNameBeyondItsCapacity() throws {
        let names = TunnelAnsweredNames(policy: try Self.policy(capacity: 2))
        let first = try DomainName("a.example")
        let second = try DomainName("b.example")
        let third = try DomainName("c.example")

        names.record([try IPAddress("192.0.2.1")], for: first, at: Self.start)
        names.record([try IPAddress("192.0.2.2")], for: second, at: Self.start)
        _ = names.addresses(for: first, at: Self.start)
        names.record([try IPAddress("192.0.2.3")], for: third, at: Self.start)

        #expect(!names.addresses(for: first, at: Self.start).isEmpty)
        #expect(names.addresses(for: second, at: Self.start).isEmpty)
        #expect(!names.addresses(for: third, at: Self.start).isEmpty)
    }

    @Test
    func rejectsAPolicyThatKeepsNothing() {
        #expect(throws: RelayPolicyError.nonPositiveTimeout) {
            try AnsweredNamesPolicy(minimumRetention: .zero, maximumRetention: .seconds(600), capacity: 16)
        }
        #expect(throws: RelayPolicyError.retentionOutOfOrder) {
            try AnsweredNamesPolicy(minimumRetention: .seconds(60), maximumRetention: .seconds(30), capacity: 16)
        }
        #expect(throws: RelayPolicyError.nonPositiveCapacity) {
            try AnsweredNamesPolicy(minimumRetention: .seconds(60), maximumRetention: .seconds(600), capacity: 0)
        }
    }

    private static func policy(capacity: Int = 16) throws -> AnsweredNamesPolicy {
        try AnsweredNamesPolicy(minimumRetention: .seconds(60), maximumRetention: .seconds(600), capacity: capacity)
    }

    private static func answers(_ name: String, _ records: [(String, UInt32)]) throws -> DNSAddressAnswers {
        let answers = try records.map { address, timeToLive in
            DNSResponseFixture.Answer.address(try IPAddress(address), timeToLive: timeToLive)
        }
        return try DNSAddressAnswers(parsing: DNSResponseFixture.response(to: name, answers: answers))
    }
}
