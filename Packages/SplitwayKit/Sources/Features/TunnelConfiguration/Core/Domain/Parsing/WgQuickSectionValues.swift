struct WgQuickSectionValues {
    private var entriesByKey: [WgQuickKey: [WgQuickRawEntry]] = [:]

    init(classifying section: WgQuickRawSection, issues: inout [ConfigurationIssue]) {
        for entry in section.entries {
            if let issueKind = classify(entry, in: section.section) {
                issues.append(ConfigurationIssue(line: entry.line, kind: issueKind))
            }
        }
    }

    func contains(_ key: WgQuickKey) -> Bool {
        entriesByKey[key] != nil
    }

    func first(_ key: WgQuickKey) -> WgQuickRawEntry? {
        entriesByKey[key]?.first
    }

    func all(_ key: WgQuickKey) -> [WgQuickRawEntry] {
        entriesByKey[key, default: []]
    }

    private mutating func classify(_ entry: WgQuickRawEntry, in section: WgQuickSection) -> ConfigurationIssueKind? {
        guard let key = WgQuickKey(name: entry.key) else {
            return ForeignWgQuickKeys.issueKind(forUnrecognizedKey: entry.key)
        }
        guard key.section == section else { return .keyNotAllowedInSection(key) }
        guard key.acceptsMultipleLines || entriesByKey[key] == nil else { return .duplicateKey(key) }
        entriesByKey[key, default: []].append(entry)
        return nil
    }
}
