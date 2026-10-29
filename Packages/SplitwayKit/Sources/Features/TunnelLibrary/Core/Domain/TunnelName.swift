import Foundation

public struct TunnelName: Sendable, Hashable {
    public static let maximumLength = 64
    public static let untitled = TunnelName(validatedText: "Tunnel")

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

    private init(validatedText: String) {
        value = validatedText
    }

    var text: String {
        value
    }
}
