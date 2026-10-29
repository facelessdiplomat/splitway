enum DNSMessageFixtures {
    static let addressType: UInt16 = 1
    static let ipv6AddressType: UInt16 = 28
    static let optionType: UInt16 = 41
    static let internetClass: UInt16 = 1
    static let cookieOption: [UInt8] = [0x00, 0x0A, 0x00, 0x08, 0x5A, 0x1B, 0x3C, 0x4D, 0x5E, 0x6F, 0x70, 0x81]

    static func name(_ text: String) -> [UInt8] {
        text.split(separator: ".").flatMap { label in [UInt8(label.utf8.count)] + Array(label.utf8) } + [0]
    }

    static func question(_ name: [UInt8], type: UInt16) -> [UInt8] {
        name + bytes(of: type) + bytes(of: internetClass)
    }

    static func optionRecord(payloadByteCount: UInt16, acceptsDNSSECRecords: Bool, options: [UInt8] = []) -> [UInt8] {
        let flags: [UInt8] = acceptsDNSSECRecords ? [0x80, 0x00] : [0x00, 0x00]
        return [0x00] + bytes(of: optionType) + bytes(of: payloadByteCount) + [0x00, 0x00] + flags
            + bytes(of: UInt16(options.count)) + options
    }

    static func message(
        id: UInt16,
        flags: UInt16,
        questions: [[UInt8]],
        additionalRecords: [[UInt8]] = [],
        additionalCount: UInt16? = nil
    ) -> [UInt8] {
        var message = bytes(of: id) + bytes(of: flags) + bytes(of: UInt16(questions.count))
        message += [0x00, 0x00, 0x00, 0x00]
        message += bytes(of: additionalCount ?? UInt16(additionalRecords.count))
        message += questions.flatMap(\.self) + additionalRecords.flatMap(\.self)
        return message
    }

    static func bytes(of value: UInt16) -> [UInt8] {
        [UInt8(value >> 8), UInt8(value & 0xFF)]
    }
}
