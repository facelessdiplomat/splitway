import Foundation

enum WgQuickLineTokenizer {
    private static let byteOrderMark: Unicode.Scalar = "\u{FEFF}"
    private static let commentMarker: Character = "#"

    static func lines(of text: String) -> [WgQuickLine] {
        withoutByteOrderMark(text)
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .enumerated()
            .compactMap { offset, rawLine in tokenize(rawLine, number: offset + 1) }
    }

    private static func withoutByteOrderMark(_ text: String) -> String {
        guard text.unicodeScalars.first == byteOrderMark else { return text }
        return String(text.unicodeScalars.dropFirst())
    }

    private static func tokenize(_ rawLine: Substring, number: Int) -> WgQuickLine? {
        let meaningfulText = rawLine.prefix { character in character != commentMarker }
            .trimmingCharacters(in: .whitespaces)
        guard !meaningfulText.isEmpty else { return nil }
        return WgQuickLine(number: number, content: content(of: meaningfulText))
    }

    private static func content(of text: String) -> WgQuickLine.Content {
        if text.hasPrefix("["), text.hasSuffix("]") {
            return .sectionHeader(text.dropFirst().dropLast().trimmingCharacters(in: .whitespaces))
        }
        guard let separator = text.firstIndex(of: "=") else { return .malformed }
        let key = text[..<separator].trimmingCharacters(in: .whitespaces)
        let value = text[text.index(after: separator)...].trimmingCharacters(in: .whitespaces)
        return key.isEmpty ? .malformed : .entry(key: key, value: value)
    }
}
