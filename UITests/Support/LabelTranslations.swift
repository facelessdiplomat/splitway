struct LabelTranslations: Sendable {
    private static let english = "en"
    private static let countPlaceholder = "%lld"
    private static let untranslatableEnglish: Set<String> = ["%@", "%@: %@"]
    private static let systemLabels = [
        "ru": [
            "Cancel": ["Отменить"],
            "Close": ["Закрыть"],
            "More": ["Еще", "Ещё"],
            "Paste": ["Вставить"],
        ]
    ]

    let language: String
    private let translations: [String: [String]]
    private let plurals: [String: [PluralCategory: [String]]]

    init(language: String, catalogs: [StringCatalog]) {
        self.language = language
        translations = Self.translationsByKey(in: catalogs, language: language)
        plurals = Self.pluralFormsByKey(in: catalogs, language: language)
    }

    func matching(_ englishLabel: String) -> [String] {
        guard language != Self.english else { return [englishLabel] }
        let candidates = translations[englishLabel] ?? Self.systemLabels[language]?[englishLabel] ?? []
        return candidates.isEmpty ? [englishLabel] : candidates
    }

    func counted(_ englishFormat: String, count: Int) -> [String] {
        let category = PluralCategory(count: count, language: language)
        let formats = plurals[englishFormat]?[category] ?? [englishFormat]
        return formats.map { format in format.replacingOccurrences(of: Self.countPlaceholder, with: String(count)) }
    }

    func isUntranslatedEnglish(_ label: String) -> Bool {
        guard language != Self.english, !Self.untranslatableEnglish.contains(label) else { return false }
        return translations[label]?.contains(label) == false
    }

    private static func translationsByKey(in catalogs: [StringCatalog], language: String) -> [String: [String]] {
        var translations: [String: [String]] = [:]
        for catalog in catalogs {
            for (key, value) in catalog.values(in: language) where translations[key]?.contains(value) != true {
                translations[key, default: []].append(value)
            }
        }
        return translations
    }

    private static func pluralFormsByKey(in catalogs: [StringCatalog], language: String)
        -> [String: [PluralCategory: [String]]]
    {
        var formsByKey: [String: [PluralCategory: [String]]] = [:]
        for catalog in catalogs {
            for (key, forms) in catalog.pluralForms(in: language) {
                for (category, form) in forms {
                    formsByKey[key, default: [:]][category, default: []].append(form)
                }
            }
        }
        return formsByKey
    }
}
