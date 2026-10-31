public struct TransferRate: Equatable, Sendable {
    private static let bitsPerByte = 8.0
    private static let bitsPerMegabit = 1_000_000.0

    public let megabitsPerSecond: Double

    public init?(byteCount: Int, duration: Duration) {
        let seconds = duration.seconds
        guard seconds > 0 else { return nil }
        megabitsPerSecond = Double(byteCount) * Self.bitsPerByte / seconds / Self.bitsPerMegabit
    }
}
