struct WgQuickSectionGrouping {
    private(set) var sections: [WgQuickRawSection] = []
    private(set) var issues: [ConfigurationIssue] = []
    private var isInsideUnknownSection = false

    init(lines: [WgQuickLine]) {
        for line in lines {
            consume(line)
        }
    }

    private mutating func consume(_ line: WgQuickLine) {
        switch line.content {
        case .sectionHeader(let name):
            openSection(named: name, at: line.number)
        case .entry(let key, let value):
            addEntry(WgQuickRawEntry(key: key, value: value, line: line.number))
        case .malformed:
            issues.append(ConfigurationIssue(line: line.number, kind: .malformedLine))
        }
    }

    private mutating func openSection(named name: String, at line: Int) {
        guard let section = WgQuickSection(name: name) else {
            issues.append(ConfigurationIssue(line: line, kind: .unknownSection(name)))
            isInsideUnknownSection = true
            return
        }
        isInsideUnknownSection = false
        sections.append(WgQuickRawSection(section: section, headerLine: line, entries: []))
    }

    private mutating func addEntry(_ entry: WgQuickRawEntry) {
        guard !isInsideUnknownSection else { return }
        guard !sections.isEmpty else {
            issues.append(ConfigurationIssue(line: entry.line, kind: .keyOutsideSection(entry.key)))
            return
        }
        sections[sections.count - 1].entries.append(entry)
    }
}
