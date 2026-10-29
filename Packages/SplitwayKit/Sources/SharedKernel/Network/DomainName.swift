public struct DomainName: Sendable, Hashable {
    public static let maximumLength = 253
    public static let maximumLabelLength = 63

    private let normalizedName: String

    public init(_ text: String) throws(DomainNameValidationError) {
        normalizedName = try DomainNameValidator.normalizedName(from: text)
    }

    public func isSameOrSubdomain(of domain: DomainName) -> Bool {
        normalizedName == domain.normalizedName || normalizedName.hasSuffix("." + domain.normalizedName)
    }

    var text: String {
        normalizedName
    }
}
