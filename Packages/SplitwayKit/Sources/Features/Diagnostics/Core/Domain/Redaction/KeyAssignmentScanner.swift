enum KeyAssignmentScanner {
    private static let secretKeyNames = ["privatekey", "presharedkey", "private_key", "preshared_key"]
        .map { name in Array(name.utf8) }
    private static let secretKeyNameInitials = Set(secretKeyNames.compactMap(\.first))
    private static let assignmentOperators: Set<UInt8> = [UInt8(ascii: "="), UInt8(ascii: ":")]

    static func valueRanges(in bytes: [UInt8]) -> [Range<Int>] {
        var ranges: [Range<Int>] = []
        var index = 0
        while index < bytes.count {
            if let valueRange = assignedSecretValue(in: bytes, startingAt: index) {
                ranges.append(valueRange)
                index = valueRange.upperBound
            } else {
                index += 1
            }
        }
        return ranges
    }

    private static func assignedSecretValue(in bytes: [UInt8], startingAt start: Int) -> Range<Int>? {
        guard let nameEnd = endOfSecretKeyName(in: bytes, at: start) else { return nil }
        let operatorIndex = indexAfterSpaces(in: bytes, from: nameEnd)
        guard operatorIndex < bytes.count, assignmentOperators.contains(bytes[operatorIndex]) else { return nil }
        let valueStart = indexAfterSpaces(in: bytes, from: operatorIndex + 1)
        let valueEnd = bytes[valueStart...].firstIndex(where: ASCIICharacterClass.isWhitespace) ?? bytes.count
        return valueStart < valueEnd ? valueStart..<valueEnd : nil
    }

    private static func endOfSecretKeyName(in bytes: [UInt8], at start: Int) -> Int? {
        guard secretKeyNameInitials.contains(ASCIICharacterClass.lowercased(bytes[start])) else { return nil }
        return secretKeyNames.first { name in startsWith(name, in: bytes, at: start) }.map { name in start + name.count
        }
    }

    private static func startsWith(_ name: [UInt8], in bytes: [UInt8], at start: Int) -> Bool {
        guard start + name.count <= bytes.count else { return false }
        return zip(name, bytes[start...]).allSatisfy { expected, byte in
            ASCIICharacterClass.lowercased(byte) == expected
        }
    }

    private static func indexAfterSpaces(in bytes: [UInt8], from start: Int) -> Int {
        bytes[start...].firstIndex { byte in !ASCIICharacterClass.isSpaceOrTab(byte) } ?? bytes.count
    }
}
