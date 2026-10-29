import Foundation

public struct TunnelName: Sendable, Hashable {
    public static let maximumLength = 64

    private let value: String

    public init(_ text: String) throws(TunnelNameError) {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { throw .empty }
        guard trimmedText.count <= Self.maximumLength else { throw .tooLong }
        guard !trimmedText.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else {
            throw .containsControlCharacters
        }
        value = trimmedText
    }

    var text: String {
        value
    }
}
