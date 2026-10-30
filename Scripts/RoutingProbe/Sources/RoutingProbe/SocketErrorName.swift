import Darwin

enum SocketErrorName {
    static func name(of code: Int32) -> String {
        switch code {
        case ECONNREFUSED: "refused"
        case ETIMEDOUT: "timeout"
        case EHOSTUNREACH: "host-unreachable"
        case ENETUNREACH: "network-unreachable"
        case ECONNRESET: "reset"
        case EADDRNOTAVAIL: "address-unavailable"
        default: "errno\(code)"
        }
    }
}
