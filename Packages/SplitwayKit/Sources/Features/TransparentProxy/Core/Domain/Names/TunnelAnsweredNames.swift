import DNSProxy
import Foundation
import SharedKernel
import Synchronization

public final class TunnelAnsweredNames: Sendable {
    private struct AnsweredAddress: Sendable {
        let address: IPAddress
        var expiry: Date
    }

    private let policy: AnsweredNamesPolicy
    private let answers: Mutex<LeastRecentlyUsedCache<DomainName, [AnsweredAddress]>>

    public init(policy: AnsweredNamesPolicy = .standard) {
        self.policy = policy
        answers = Mutex(LeastRecentlyUsedCache(capacity: policy.capacity))
    }

    public func record(_ answers: DNSAddressAnswers, at moment: Date) {
        let answered = answers.records.map { record in
            AnsweredAddress(
                address: record.address,
                expiry: moment.addingTimeInterval(policy.retention(forTimeToLive: record.timeToLive))
            )
        }
        merge(answered, for: answers.name, at: moment)
    }

    public func record(_ addresses: [IPAddress], for name: DomainName, at moment: Date) {
        let expiry = moment.addingTimeInterval(policy.minimumRetentionInterval)
        merge(addresses.map { address in AnsweredAddress(address: address, expiry: expiry) }, for: name, at: moment)
    }

    public func addresses(for name: DomainName, at moment: Date) -> [IPAddress] {
        answers.withLock { cache in
            (cache.value(for: name) ?? []).filter { answered in answered.expiry > moment }.map(\.address)
        }
    }

    private func merge(_ answered: [AnsweredAddress], for name: DomainName, at moment: Date) {
        guard !answered.isEmpty else { return }
        answers.withLock { cache in
            var merged = (cache.value(for: name) ?? []).filter { known in known.expiry > moment }
            for answer in answered {
                if let index = merged.firstIndex(where: { known in known.address == answer.address }) {
                    merged[index].expiry = max(merged[index].expiry, answer.expiry)
                } else {
                    merged.append(answer)
                }
            }
            cache.insert(merged, for: name)
        }
    }
}
