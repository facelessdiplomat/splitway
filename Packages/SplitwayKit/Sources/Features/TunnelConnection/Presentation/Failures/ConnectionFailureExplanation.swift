import Foundation

public struct ConnectionFailureExplanation: Sendable {
    public let title: LocalizedStringResource
    public let message: LocalizedStringResource
    public let suggestedAction: ConnectionFailureAction
}
