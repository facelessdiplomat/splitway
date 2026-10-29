enum KeyTokenScanner {
    private static let base64KeyBodyLength = 43
    private static let hexKeyLength = 64
    private static let padding = UInt8(ascii: "=")
    private static let finalBase64KeyCharacters = Set("AEIMQUYcgkosw048".utf8)

    static func keyRanges(in bytes: [UInt8]) -> [Range<Int>] {
        var ranges: [Range<Int>] = []
        var runStart = 0
        while runStart < bytes.count {
            guard ASCIICharacterClass.isBase64Alphabet(bytes[runStart]) else {
                runStart += 1
                continue
            }
            let runEnd = bytes[runStart...].firstIndex { byte in !ASCIICharacterClass.isBase64Alphabet(byte) }
            let run = runStart..<(runEnd ?? bytes.count)
            if let keyRange = keyRange(spanning: run, in: bytes) {
                ranges.append(keyRange)
            }
            runStart = run.upperBound
        }
        return ranges
    }

    private static func keyRange(spanning run: Range<Int>, in bytes: [UInt8]) -> Range<Int>? {
        if run.count == hexKeyLength, bytes[run].allSatisfy(ASCIICharacterClass.isHexDigit) {
            return run
        }
        guard run.count == base64KeyBodyLength,
            finalBase64KeyCharacters.contains(bytes[run.upperBound - 1]),
            run.upperBound < bytes.count,
            bytes[run.upperBound] == padding
        else { return nil }
        let keyEnd = run.upperBound + 1
        guard keyEnd == bytes.count || !ASCIICharacterClass.isBase64AlphabetOrPadding(bytes[keyEnd]) else {
            return nil
        }
        return run.lowerBound..<keyEnd
    }
}
