import Foundation

extension ThirdPartyNotice {
    private static let listItemMarkers: Set<Character> = ["*", "-", "•"]

    public var paragraphs: [String] {
        var paragraphs: [String] = []
        var lines: [String] = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty || Self.startsListItem(trimmedLine), !lines.isEmpty {
                paragraphs.append(lines.joined(separator: " "))
                lines.removeAll()
            }
            if !trimmedLine.isEmpty {
                lines.append(trimmedLine)
            }
        }
        if !lines.isEmpty {
            paragraphs.append(lines.joined(separator: " "))
        }
        return paragraphs
    }

    private static func startsListItem(_ line: String) -> Bool {
        guard let marker = line.first, listItemMarkers.contains(marker) else { return false }
        return line.dropFirst().first == " "
    }
}
