import Foundation

public enum ImportPayload: Sendable, Hashable {
    case text(String)
    case qrCode(String)
    case file(name: String, contents: Data)
}
