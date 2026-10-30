struct ProbeLine {
    let check: String
    let outcome: String
    let detail: String
    let elapsed: Duration

    var text: String {
        let milliseconds = elapsed.components.seconds * 1_000 + elapsed.components.attoseconds / 1_000_000_000_000_000
        return [check, outcome, detail, "\(milliseconds)ms"].filter { field in !field.isEmpty }.joined(separator: " ")
    }
}
