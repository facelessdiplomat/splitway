public struct DNSQuery: Sendable, Hashable {
    public static let addressType: UInt16 = 1
    private static let internetClass: UInt16 = 1
    private static let recursionDesiredFlags: [UInt8] = [0x01, 0x00]
    private static let emptySectionCounts: [UInt8] = [0, 0, 0, 0, 0, 0]
    private static let maximumLabelLength = 63
    private static let maximumNameLength = 253
    private static let labelSeparator: Character = "."

    public let identifier: UInt16
    public let name: String
    public let type: UInt16

    public init(identifier: UInt16, name: String, type: UInt16 = addressType) throws(DNSQueryError) {
        let labels = name.split(separator: Self.labelSeparator, omittingEmptySubsequences: false)
        guard !name.isEmpty, name.utf8.count <= Self.maximumNameLength,
            labels.allSatisfy({ label in !label.isEmpty && label.utf8.count <= Self.maximumLabelLength })
        else { throw .invalidName }
        self.identifier = identifier
        self.name = name
        self.type = type
    }

    public var bytes: [UInt8] {
        var message = Self.bytes(of: identifier) + Self.recursionDesiredFlags + Self.bytes(of: 1)
        message += Self.emptySectionCounts
        for label in name.split(separator: Self.labelSeparator) {
            message.append(UInt8(label.utf8.count))
            message += Array(label.utf8)
        }
        message.append(0)
        return message + Self.bytes(of: type) + Self.bytes(of: Self.internetClass)
    }

    private static func bytes(of value: UInt16) -> [UInt8] {
        [UInt8(value >> 8), UInt8(value & 0xFF)]
    }
}
