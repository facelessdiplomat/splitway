import Darwin
import SharedKernel

enum SocketAddressReader {
    static func address(of info: addrinfo) -> SharedKernel.IPAddress? {
        guard let socketAddress = info.ai_addr else { return nil }
        switch info.ai_family {
        case AF_INET:
            return socketAddress.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { ipv4 in
                .ipv4(UInt32(bigEndian: ipv4.pointee.sin_addr.s_addr))
            }
        case AF_INET6:
            return socketAddress.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { ipv6 in
                withUnsafeBytes(of: ipv6.pointee.sin6_addr) { bytes in
                    .ipv6(bytes.reduce(UInt128.zero) { value, byte in value << 8 | UInt128(byte) })
                }
            }
        default:
            return nil
        }
    }
}
