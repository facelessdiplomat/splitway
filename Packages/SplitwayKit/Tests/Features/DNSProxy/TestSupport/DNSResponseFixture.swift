import SharedKernel

public enum DNSResponseFixture {
    public enum Answer: Sendable {
        case address(IPAddress, timeToLive: UInt32)
        case alias(String, timeToLive: UInt32)
    }

    private static let questionNamePointer: [UInt8] = [0xC0, 0x0C]
    private static let addressType: UInt16 = 1
    private static let aliasType: UInt16 = 5
    private static let ipv6AddressType: UInt16 = 28
    private static let internetClass: UInt16 = 1
    private static let responseFlags: UInt16 = 0x8180
    private static let queryFlags: UInt16 = 0x0100
    private static let defaultIdentifier: UInt16 = 0x2A2A

    public static func response(to name: String, answers: [Answer], responseCode: UInt8 = 0) -> [UInt8] {
        var message = bytes(of: defaultIdentifier) + bytes(of: responseFlags | UInt16(responseCode))
        message += bytes(of: 1) + bytes(of: UInt16(answers.count)) + bytes(of: 0) + bytes(of: 0)
        message += question(name)
        for answer in answers {
            message += record(answer)
        }
        return message
    }

    public static func query(for name: String) -> [UInt8] {
        bytes(of: defaultIdentifier) + bytes(of: queryFlags) + bytes(of: 1) + bytes(of: 0) + bytes(of: 0)
            + bytes(of: 0) + question(name)
    }

    public static func bytes(of value: UInt16) -> [UInt8] {
        [UInt8(value >> 8), UInt8(truncatingIfNeeded: value)]
    }

    private static func question(_ name: String) -> [UInt8] {
        encoded(name) + bytes(of: addressType) + bytes(of: internetClass)
    }

    private static func encoded(_ name: String) -> [UInt8] {
        name.split(separator: ".").flatMap { label in [UInt8(label.utf8.count)] + Array(label.utf8) } + [0]
    }

    private static func record(_ answer: Answer) -> [UInt8] {
        switch answer {
        case .address(let address, let timeToLive):
            let type = address.family == .ipv4 ? addressType : ipv6AddressType
            return resourceRecord(type: type, timeToLive: timeToLive, data: address.networkOrderBytes)
        case .alias(let target, let timeToLive):
            return resourceRecord(type: aliasType, timeToLive: timeToLive, data: encoded(target))
        }
    }

    private static func resourceRecord(type: UInt16, timeToLive: UInt32, data: [UInt8]) -> [UInt8] {
        questionNamePointer + bytes(of: type) + bytes(of: internetClass)
            + bytes(of: UInt16(timeToLive >> 16)) + bytes(of: UInt16(truncatingIfNeeded: timeToLive))
            + bytes(of: UInt16(data.count)) + data
    }
}
