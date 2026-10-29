public enum UniqueTunnelNameResolver {
    private static let firstDisambiguatingNumber = 2

    public static func uniqueName(for proposedName: TunnelName, takenNames: [TunnelName]) -> TunnelName {
        let takenKeys = Set(takenNames.map(comparisonKey))
        guard takenKeys.contains(comparisonKey(of: proposedName)) else { return proposedName }
        var number = firstDisambiguatingNumber
        while true {
            let candidate = numberedName(proposedName, number: number)
            if !takenKeys.contains(comparisonKey(of: candidate)) {
                return candidate
            }
            number += 1
        }
    }

    private static func numberedName(_ baseName: TunnelName, number: Int) -> TunnelName {
        let suffix = " \(number)"
        let shortenedBase = baseName.text.prefix(TunnelName.maximumLength - suffix.count)
        return (try? TunnelName(shortenedBase + suffix)) ?? baseName
    }

    private static func comparisonKey(of name: TunnelName) -> String {
        name.text.lowercased()
    }
}
