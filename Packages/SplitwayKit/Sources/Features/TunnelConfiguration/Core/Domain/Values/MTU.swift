import SharedKernel

public struct MTU: Sendable, Hashable {
    public static let supportedRange: ClosedRange<Int> = 576...9_000

    public let value: Int

    public init(_ value: Int) throws(MTUValidationError) {
        guard Self.supportedRange.contains(value) else { throw .outOfRange }
        self.value = value
    }

    public init(_ text: String) throws(MTUValidationError) {
        guard let value = CanonicalDecimalText.integerValue(of: text) else { throw .notANumber }
        try self.init(value)
    }
}
