public struct ServiceIcon: Sendable, Hashable {
    private static let maximumMonogramLength = 2

    public let monogram: String
    public let tint: ServiceTint

    public init(monogram: String, tint: ServiceTint) throws(ServiceIconError) {
        guard (1...Self.maximumMonogramLength).contains(monogram.count), !monogram.contains(where: \.isWhitespace)
        else {
            throw .malformedMonogram
        }
        self.init(validatedMonogram: monogram, tint: tint)
    }

    init(validatedMonogram monogram: String, tint: ServiceTint) {
        self.monogram = monogram
        self.tint = tint
    }
}
