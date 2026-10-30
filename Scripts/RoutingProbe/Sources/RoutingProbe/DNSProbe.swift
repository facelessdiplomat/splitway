import Darwin
import Foundation
import RoutingProbeCore

struct DNSProbe {
    private static let resolverConfigurationPath = "/etc/resolv.conf"
    private static let dnsPort = "53"
    private static let timeoutMilliseconds: Int32 = 5_000
    private static let replyBufferByteCount = 1_500
    private static let resolverIdentityName = "whoami.akamai.net"

    func run() -> ProbeLine {
        let clock = ContinuousClock()
        let start = clock.now
        let outcome = resolve()
        return ProbeLine(
            check: "resolver", outcome: outcome.outcome, detail: outcome.detail, elapsed: clock.now - start)
    }

    private func resolve() -> (outcome: String, detail: String) {
        guard let text = try? String(contentsOfFile: Self.resolverConfigurationPath, encoding: .utf8),
            let resolver = ResolverConfiguration.firstNameserver(in: text)
        else { return ("failed", "no-resolver") }
        let identifier = UInt16.random(in: .min ... .max)
        guard let query = try? DNSQuery(identifier: identifier, name: Self.resolverIdentityName) else {
            return ("failed", "invalid-query")
        }
        switch exchange(query.bytes, with: resolver) {
        case .failure(let reason):
            return ("failed", reason.text)
        case .success(let bytes):
            guard let reply = try? DNSReply(parsing: bytes), reply.identifier == identifier else {
                return ("failed", "malformed-reply")
            }
            return ("ok", ([reply.responseCode.description] + reply.addresses.prefix(1)).joined(separator: " "))
        }
    }

    private func exchange(_ query: [UInt8], with resolver: String) -> Result<[UInt8], ProbeFailure> {
        var hints = addrinfo()
        hints.ai_flags = AI_NUMERICHOST | AI_NUMERICSERV
        hints.ai_socktype = SOCK_DGRAM
        var info: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(resolver, Self.dnsPort, &hints, &info) == 0, let address = info else {
            return .failure(ProbeFailure("bad-resolver"))
        }
        defer { freeaddrinfo(info) }
        let descriptor = socket(address.pointee.ai_family, SOCK_DGRAM, IPPROTO_UDP)
        guard descriptor >= 0 else { return .failure(ProbeFailure(errno: errno)) }
        defer { close(descriptor) }
        let sent = query.withUnsafeBytes { bytes in
            sendto(descriptor, bytes.baseAddress, bytes.count, 0, address.pointee.ai_addr, address.pointee.ai_addrlen)
        }
        guard sent == query.count else { return .failure(ProbeFailure(errno: errno)) }
        var waiting = pollfd(fd: descriptor, events: Int16(POLLIN), revents: 0)
        let ready = poll(&waiting, 1, Self.timeoutMilliseconds)
        guard ready > 0 else { return .failure(ready == 0 ? ProbeFailure("timeout") : ProbeFailure(errno: errno)) }
        var buffer = [UInt8](repeating: 0, count: Self.replyBufferByteCount)
        let received = buffer.withUnsafeMutableBytes { bytes in recv(descriptor, bytes.baseAddress, bytes.count, 0) }
        guard received > 0 else { return .failure(ProbeFailure(errno: errno)) }
        return .success(Array(buffer.prefix(received)))
    }
}
