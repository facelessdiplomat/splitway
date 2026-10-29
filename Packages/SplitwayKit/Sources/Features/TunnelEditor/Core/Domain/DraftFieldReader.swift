import TunnelConfiguration

struct DraftFieldReader {
    private(set) var problems: [TunnelDraftProblem] = []

    mutating func required<Value>(
        _ text: String,
        as field: TunnelDraftField,
        using parse: (String) throws(ConfigurationValueError) -> Value
    ) -> Value? {
        let value = text.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else {
            report(.missing, for: field)
            return nil
        }
        return parsed(value, as: field, using: parse)
    }

    mutating func optional<Value>(
        _ text: String,
        as field: TunnelDraftField,
        using parse: (String) throws(ConfigurationValueError) -> Value
    ) -> Value? {
        let value = text.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        return parsed(value, as: field, using: parse)
    }

    mutating func report(_ reason: TunnelDraftProblemReason, for field: TunnelDraftField) {
        problems.append(TunnelDraftProblem(field: field, reason: reason))
    }

    private mutating func parsed<Value>(
        _ value: String,
        as field: TunnelDraftField,
        using parse: (String) throws(ConfigurationValueError) -> Value
    ) -> Value? {
        do {
            return try parse(value)
        } catch {
            report(.invalidValue(error), for: field)
            return nil
        }
    }
}
