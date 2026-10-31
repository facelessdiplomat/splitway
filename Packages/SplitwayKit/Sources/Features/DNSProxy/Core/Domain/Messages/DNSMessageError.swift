public enum DNSMessageError: Error, Equatable, Sendable {
    case truncatedHeader
    case notAQuery
    case notAResponse
    case malformedQuestion
    case malformedRecord
}
