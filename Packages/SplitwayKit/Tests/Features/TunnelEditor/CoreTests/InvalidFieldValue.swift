import TunnelEditor

struct InvalidFieldValue<Field: Sendable>: Sendable {
    let field: Field
    let text: String
    let reason: TunnelDraftProblemReason

    init(_ field: Field, _ text: String, _ reason: TunnelDraftProblemReason) {
        self.field = field
        self.text = text
        self.reason = reason
    }
}
