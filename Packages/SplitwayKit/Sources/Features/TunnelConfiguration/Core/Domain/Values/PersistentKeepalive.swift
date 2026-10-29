import SharedKernel

public struct PersistentKeepalive: Sendable, Hashable {
    public static let validIntervalRange: ClosedRange<Int> = 1...65_535
    private static let disabledSpellings: Set<String> = ["0", "off"]

    public let seconds: Int

    public init(seconds: Int) throws(PersistentKeepaliveValidationError) {
        guard Self.validIntervalRange.contains(seconds) else { throw .outOfRange }
        self.seconds = seconds
    }

    public static func parse(_ text: String) throws(PersistentKeepaliveValidationError) -> PersistentKeepalive? {
        guard !disabledSpellings.contains(text.lowercased()) else { return nil }
        guard let seconds = CanonicalDecimalText.integerValue(of: text) else { throw .notANumber }
        return try PersistentKeepalive(seconds: seconds)
    }
}
