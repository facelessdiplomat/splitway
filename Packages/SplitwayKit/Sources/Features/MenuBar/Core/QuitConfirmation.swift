public protocol QuitConfirmation: Sendable {
    @MainActor
    func decision(forActiveTunnelNamed name: String) async -> QuitDecision
}
