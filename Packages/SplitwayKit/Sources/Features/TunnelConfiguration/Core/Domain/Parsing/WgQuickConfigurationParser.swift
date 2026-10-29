public enum WgQuickConfigurationParser {
    public static let maximumConfigurationSize = 65_536

    public static func parse(_ text: String) -> WgQuickParsingResult {
        guard text.utf8.count <= maximumConfigurationSize else {
            return WgQuickParsingResult(
                configuration: nil,
                issues: [ConfigurationIssue(line: nil, kind: .configurationTooLarge)]
            )
        }
        let grouping = WgQuickSectionGrouping(lines: WgQuickLineTokenizer.lines(of: text))
        var issues = grouping.issues
        let configuration = WgQuickConfigurationAssembler.assemble(grouping.sections, issues: &issues)
        return WgQuickParsingResult(configuration: configuration, issues: issues.sorted(by: Self.isOrderedBefore))
    }

    private static func isOrderedBefore(_ first: ConfigurationIssue, _ second: ConfigurationIssue) -> Bool {
        (first.line ?? 0) < (second.line ?? 0)
    }
}
