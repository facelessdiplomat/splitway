public enum DNSResponseCode: Sendable, Hashable, CustomStringConvertible {
    case noError
    case formatError
    case serverFailure
    case nameError
    case notImplemented
    case refused
    case other(UInt8)

    init(_ value: UInt8) {
        switch value {
        case 0: self = .noError
        case 1: self = .formatError
        case 2: self = .serverFailure
        case 3: self = .nameError
        case 4: self = .notImplemented
        case 5: self = .refused
        default: self = .other(value)
        }
    }

    public var description: String {
        switch self {
        case .noError: "NOERROR"
        case .formatError: "FORMERR"
        case .serverFailure: "SERVFAIL"
        case .nameError: "NXDOMAIN"
        case .notImplemented: "NOTIMP"
        case .refused: "REFUSED"
        case .other(let code): "RCODE\(code)"
        }
    }
}
