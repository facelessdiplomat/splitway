public struct NetworkPort: Sendable, Hashable {
    public static let validRange: ClosedRange<Int> = 1...65_535
    private static let maximumDigits = 5

    public let value: UInt16

    public init(_ number: Int) throws(NetworkPortValidationError) {
        guard Self.validRange.contains(number) else { throw .outOfRange }
        value = UInt16(number)
    }

    public init(_ text: String) throws(NetworkPortValidationError) {
        guard CanonicalDecimalText.isCanonical(text[...], maximumDigits: Self.maximumDigits), let number = Int(text)
        else { throw .notANumber }
        try self.init(number)
    }
}
