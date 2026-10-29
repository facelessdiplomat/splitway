public enum LogRedactor {
    public static let mask = "[redacted]"

    public static func redact(_ text: String) -> String {
        let bytes = Array(text.utf8)
        let secretRanges = KeyAssignmentScanner.valueRanges(in: bytes) + KeyTokenScanner.keyRanges(in: bytes)
        guard !secretRanges.isEmpty else { return text }
        return masking(mergedRanges(secretRanges), in: bytes)
    }

    private static func mergedRanges(_ ranges: [Range<Int>]) -> [Range<Int>] {
        ranges.sorted { first, second in first.lowerBound < second.lowerBound }
            .reduce(into: []) { merged, range in
                if let last = merged.last, range.lowerBound <= last.upperBound {
                    merged[merged.count - 1] = last.lowerBound..<max(last.upperBound, range.upperBound)
                } else {
                    merged.append(range)
                }
            }
    }

    private static func masking(_ ranges: [Range<Int>], in bytes: [UInt8]) -> String {
        var masked: [UInt8] = []
        masked.reserveCapacity(bytes.count)
        var position = 0
        for range in ranges {
            masked += bytes[position..<range.lowerBound]
            masked += mask.utf8
            position = range.upperBound
        }
        masked += bytes[position...]
        return String(bytes: masked, encoding: .utf8) ?? mask
    }
}
