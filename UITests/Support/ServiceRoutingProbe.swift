import XCTest

enum ServiceRoutingProbe {
    private static let requestTimeout: TimeInterval = 15
    private static let idleTimeout: TimeInterval = 30
    private static let loadTimeout: TimeInterval = 600
    private static let fakeIPv4Network: UInt32 = 0xC612_0000
    private static let fakeIPv4Mask: UInt32 = 0xFFFE_0000
    private static let fakeIPv6Prefix: [UInt8] = [0x20, 0x01, 0x00, 0x02, 0x00, 0x00]
    private static let mappedIPv4Prefix: [UInt8] = Array(repeating: 0, count: 10) + [0xFF, 0xFF]
    private static let traceAddressPrefix = "ip="

    static func text(at address: String) async throws -> String {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: try XCTUnwrap(URL(string: address)))
        request.timeoutInterval = requestTimeout
        let (data, _) = try await session.data(for: request)
        return String(bytes: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func traceAddress(of host: String) async throws -> String? {
        let trace = try await text(at: "https://\(host)/cdn-cgi/trace")
        return trace.split(separator: "\n")
            .first { line in line.hasPrefix(traceAddressPrefix) }
            .map { line in String(line.dropFirst(traceAddressPrefix.count)) }
    }

    static func addressKinds(of host: String) -> ResolvedAddressKinds {
        var kinds = ResolvedAddressKinds()
        for address in ipv4Addresses(of: host) {
            if isFake(address) {
                kinds.fakeIPv4 += 1
            } else {
                kinds.realIPv4 += 1
            }
        }
        for address in ipv6Addresses(of: host) {
            if isFake(address) {
                kinds.fakeIPv6 += 1
            } else if !isFake(embeddedIPv4(in: address)) {
                kinds.realIPv6 += 1
            } else if address.starts(with: mappedIPv4Prefix) {
                kinds.mappedFakeIPv4 += 1
            } else {
                kinds.synthesizedFromFakeIPv4 += 1
            }
        }
        return kinds
    }

    static func traceOutcome(of host: String, tunnelAddress: String, directAddresses: [String]) async -> String {
        let address: String?
        do {
            address = try await traceAddress(of: host)
        } catch {
            return "error-\((error as? URLError)?.code.rawValue ?? 0)"
        }
        guard let address else { return "no-address" }
        if address == tunnelAddress {
            return "tunnel"
        }
        let family = address.contains(":") ? "ipv6" : "ipv4"
        return directAddresses.contains(address) ? "direct-\(family)" : "other-\(family)"
    }

    static func downloadedByteCount(from address: String) async throws -> Int {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = idleTimeout
        configuration.timeoutIntervalForResource = loadTimeout
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let (location, _) = try await session.download(from: try XCTUnwrap(URL(string: address)))
        defer { try? FileManager.default.removeItem(at: location) }
        return try location.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }

    private static func isFake(_ address: UInt32) -> Bool {
        address & fakeIPv4Mask == fakeIPv4Network
    }

    private static func isFake(_ address: [UInt8]) -> Bool {
        address.starts(with: fakeIPv6Prefix)
    }

    private static func embeddedIPv4(in address: [UInt8]) -> UInt32 {
        address.suffix(MemoryLayout<UInt32>.size).reduce(0) { value, byte in value << 8 | UInt32(byte) }
    }

    private static func ipv4Addresses(of host: String) -> [UInt32] {
        addresses(of: host, family: AF_INET) { address in
            address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { ipv4 in
                UInt32(bigEndian: ipv4.pointee.sin_addr.s_addr)
            }
        }
    }

    private static func ipv6Addresses(of host: String) -> [[UInt8]] {
        addresses(of: host, family: AF_INET6) { address in
            address.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { ipv6 in
                withUnsafeBytes(of: ipv6.pointee.sin6_addr) { bytes in Array(bytes) }
            }
        }
    }

    private static func addresses<Address>(
        of host: String,
        family: Int32,
        reading read: (UnsafeMutablePointer<sockaddr>) -> Address
    ) -> [Address] {
        var hints = addrinfo()
        hints.ai_family = family
        hints.ai_socktype = SOCK_STREAM
        var list: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &list) == 0, let first = list else { return [] }
        defer { freeaddrinfo(first) }
        return sequence(first: first) { entry in entry.pointee.ai_next }
            .compactMap { entry in entry.pointee.ai_addr }
            .map(read)
    }
}
