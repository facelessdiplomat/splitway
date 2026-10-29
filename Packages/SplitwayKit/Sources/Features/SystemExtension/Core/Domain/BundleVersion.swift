import SharedKernel

public struct BundleVersion: Sendable, Hashable, Comparable {
    private static let componentSeparator: Character = "."

    private let significantComponents: [Int]

    public init?(_ text: String) {
        var components: [Int] = []
        for part in text.split(separator: Self.componentSeparator, omittingEmptySubsequences: false) {
            guard let component = CanonicalDecimalText.integerValue(of: part) else { return nil }
            components.append(component)
        }
        while components.last == 0 {
            components.removeLast()
        }
        significantComponents = components
    }

    public static func < (lhs: BundleVersion, rhs: BundleVersion) -> Bool {
        let componentCount = max(lhs.significantComponents.count, rhs.significantComponents.count)
        return lhs.components(paddedTo: componentCount)
            .lexicographicallyPrecedes(rhs.components(paddedTo: componentCount))
    }

    private func components(paddedTo count: Int) -> [Int] {
        significantComponents + Array(repeating: 0, count: count - significantComponents.count)
    }
}
