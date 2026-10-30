import Foundation

struct TransactionTimes: Sendable {
    let domainLookup: TimeInterval?
    let connection: TimeInterval?
    let secureConnection: TimeInterval?
    let firstByte: TimeInterval?
    let transfer: TimeInterval?

    init(_ transaction: URLSessionTaskTransactionMetrics) {
        domainLookup = Self.interval(transaction.domainLookupStartDate, transaction.domainLookupEndDate)
        connection = Self.interval(
            transaction.connectStartDate, transaction.secureConnectionStartDate ?? transaction.connectEndDate)
        secureConnection = Self.interval(transaction.secureConnectionStartDate, transaction.secureConnectionEndDate)
        firstByte = Self.interval(transaction.requestStartDate, transaction.responseStartDate)
        transfer = Self.interval(transaction.responseStartDate, transaction.responseEndDate)
    }

    private static func interval(_ start: Date?, _ end: Date?) -> TimeInterval? {
        guard let start, let end else { return nil }
        return end.timeIntervalSince(start)
    }
}
