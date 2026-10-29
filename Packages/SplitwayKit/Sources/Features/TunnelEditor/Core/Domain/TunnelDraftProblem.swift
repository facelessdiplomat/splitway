public struct TunnelDraftProblem: Sendable, Equatable {
    public let field: TunnelDraftField
    public let reason: TunnelDraftProblemReason

    public init(field: TunnelDraftField, reason: TunnelDraftProblemReason) {
        self.field = field
        self.reason = reason
    }
}
