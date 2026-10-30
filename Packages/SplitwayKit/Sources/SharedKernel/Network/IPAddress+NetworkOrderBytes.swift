extension IPAddress {
    private static let bitsPerByte = 8

    public init?(networkOrderBytes bytes: some Collection<UInt8>) {
        let family: IPAddressFamily
        switch bytes.count * Self.bitsPerByte {
        case IPAddressFamily.ipv4.bitWidth: family = .ipv4
        case IPAddressFamily.ipv6.bitWidth: family = .ipv6
        default: return nil
        }
        let value = bytes.reduce(UInt128(0)) { value, byte in value << Self.bitsPerByte | UInt128(byte) }
        self.init(family: family, value: value)
    }

    public var networkOrderBytes: [UInt8] {
        let byteCount = family.bitWidth / Self.bitsPerByte
        return (0..<byteCount).map { index in
            UInt8(truncatingIfNeeded: value >> (Self.bitsPerByte * (byteCount - 1 - index)))
        }
    }
}
