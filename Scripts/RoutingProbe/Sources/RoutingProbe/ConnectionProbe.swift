import Darwin

struct ConnectionProbe {
    private static let ipv6Destination = "2606:4700:4700::1111"
    private static let port = "443"
    private static let timeoutMilliseconds: Int32 = 5_000

    func run() -> ProbeLine {
        let clock = ContinuousClock()
        let start = clock.now
        let outcome: (outcome: String, detail: String)
        switch connect() {
        case .success: outcome = ("ok", "connected")
        case .failure(let reason): outcome = ("failed", reason.text)
        }
        return ProbeLine(check: "ipv6", outcome: outcome.outcome, detail: outcome.detail, elapsed: clock.now - start)
    }

    private func connect() -> Result<Void, ProbeFailure> {
        var hints = addrinfo()
        hints.ai_flags = AI_NUMERICHOST | AI_NUMERICSERV
        hints.ai_family = AF_INET6
        hints.ai_socktype = SOCK_STREAM
        var info: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(Self.ipv6Destination, Self.port, &hints, &info) == 0, let address = info else {
            return .failure(ProbeFailure("bad-destination"))
        }
        defer { freeaddrinfo(info) }
        let descriptor = socket(AF_INET6, SOCK_STREAM, IPPROTO_TCP)
        guard descriptor >= 0 else { return .failure(ProbeFailure(errno: errno)) }
        defer { close(descriptor) }
        _ = fcntl(descriptor, F_SETFL, fcntl(descriptor, F_GETFL) | O_NONBLOCK)
        if Darwin.connect(descriptor, address.pointee.ai_addr, address.pointee.ai_addrlen) == 0 { return .success(()) }
        guard errno == EINPROGRESS else { return .failure(ProbeFailure(errno: errno)) }
        var waiting = pollfd(fd: descriptor, events: Int16(POLLOUT), revents: 0)
        let ready = poll(&waiting, 1, Self.timeoutMilliseconds)
        guard ready > 0 else { return .failure(ready == 0 ? ProbeFailure("timeout") : ProbeFailure(errno: errno)) }
        var socketError: Int32 = 0
        var length = socklen_t(MemoryLayout<Int32>.size)
        getsockopt(descriptor, SOL_SOCKET, SO_ERROR, &socketError, &length)
        return socketError == 0 ? .success(()) : .failure(ProbeFailure(errno: socketError))
    }
}
