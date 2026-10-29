struct WgQuickRawEntry {
    let key: String
    let value: String
    let line: Int
}

struct WgQuickRawSection {
    let section: WgQuickSection
    let headerLine: Int
    var entries: [WgQuickRawEntry]
}
