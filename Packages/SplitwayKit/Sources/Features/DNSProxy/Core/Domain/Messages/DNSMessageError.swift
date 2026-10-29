public enum DNSMessageError: Error, Equatable, Sendable {
    case truncatedHeader
    case notAQuery
    case malformedQuestion
    case malformedRecord
}
