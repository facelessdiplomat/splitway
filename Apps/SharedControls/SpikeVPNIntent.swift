import AppIntents

struct SpikeVPNIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Turn Splitway On or Off"

    @Parameter(title: "Connected")
    var value: Bool

    func perform() async throws -> some IntentResult {
        SpikeLog.record("perform value=\(value)")
        await SpikeVPN.setActive(value)
        return .result()
    }
}
