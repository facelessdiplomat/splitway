enum IPv4AddressFormatter {
    private static let octetShifts = stride(from: 24, through: 0, by: -8)
    private static let octetMask: UInt32 = 0xFF

    static func format(_ value: UInt32) -> String {
        octetShifts.map { shift in String(value >> shift & octetMask) }.joined(separator: ".")
    }
}
