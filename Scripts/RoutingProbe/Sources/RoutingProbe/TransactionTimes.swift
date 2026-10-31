import Foundation

struct TransactionTimes: Sendable {
    private static let unknownProtocol = "unknown"

    let domainLookup: TimeInterval?
    let connection: TimeInterval?
    let secureConnection: TimeInterval?
    let firstByte: TimeInterval?
    let networkProtocol: String

    init(_ transaction: URLSessionTaskTransactionMetrics) {
        domainLookup = Self.interval(transaction.domainLookupStartDate, transaction.domainLookupEndDate)
        connection = Self.interval(
            transaction.connectStartDate, transaction.secureConnectionStartDate ?? transaction.connectEndDate)
        secureConnection = Self.interval(transaction.secureConnectionStartDate, transaction.secureConnectionEndDate)
        firstByte = Self.interval(transaction.requestStartDate, transaction.responseStartDate)
        networkProtocol = transaction.networkProtocolName ?? Self.unknownProtocol
    }

    private static func interval(_ start: Date?, _ end: Date?) -> TimeInterval? {
        guard let start, let end else { return nil }
        return end.timeIntervalSince(start)
    }
}
