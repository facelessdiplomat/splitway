import Foundation

enum LocalizedLabels {
    private static let languageVariable = "SPLITWAY_UI_TEST_LANGUAGE"
    private static let english = "en"
    private static let regions = ["en": "en_US", "ru": "ru_RU"]
    private static let catalogFolders = ["Apps", "Packages/SplitwayKit/Sources"]

    static let language = ProcessInfo.processInfo.environment[languageVariable] ?? english

    static let catalogs: [StringCatalog] = {
        let root = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        return catalogFolders.flatMap { folder in StringCatalog.all(in: root.appending(path: folder)) }
    }()

    static let translations = LabelTranslations(language: language, catalogs: catalogs)

    static var launchArguments: [String] {
        ["-AppleLanguages", "(\(language))", "-AppleLocale", regions[language] ?? language]
    }

    static func matching(_ englishLabel: String) -> [String] {
        translations.matching(englishLabel)
    }

    static func counted(_ englishFormat: String, count: Int) -> [String] {
        translations.counted(englishFormat, count: count)
    }

    static func isUntranslatedEnglish(_ label: String) -> Bool {
        translations.isUntranslatedEnglish(label)
    }

    static func predicate(_ englishLabel: String) -> NSPredicate {
        let labels = matching(englishLabel)
        return NSPredicate(format: "label IN %@ OR identifier IN %@", labels, labels)
    }

    static func prefixPredicate(_ englishPrefix: String) -> NSPredicate {
        NSCompoundPredicate(
            orPredicateWithSubpredicates: matching(englishPrefix).map { prefix in
                NSPredicate(format: "label BEGINSWITH %@", prefix)
            })
    }
}
