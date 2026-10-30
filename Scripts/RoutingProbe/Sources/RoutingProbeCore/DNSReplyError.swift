public enum DNSReplyError: Error, Sendable, Equatable {
    case notAReply
    case truncated
}
