import Foundation

struct StringCatalog: Decodable, Sendable {
    private struct Entry: Decodable, Sendable {
        let localizations: [String: Localization]?
    }

    private struct Localization: Decodable, Sendable {
        let stringUnit: StringUnit?
        let variations: Variations?
    }

    private struct StringUnit: Decodable, Sendable {
        let value: String
    }

    private struct Variations: Decodable, Sendable {
        let plural: [String: Localization]?
    }

    private static let fileExtension = "xcstrings"

    private let strings: [String: Entry]

    static func all(in folder: URL) -> [StringCatalog] {
        let files = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)
        let catalogURLs = (files?.allObjects as? [URL] ?? []).filter { url in url.pathExtension == fileExtension }
        return catalogURLs.compactMap { url in
            (try? Data(contentsOf: url)).flatMap { data in try? JSONDecoder().decode(StringCatalog.self, from: data) }
        }
    }

    func values(in language: String) -> [(key: String, value: String)] {
        strings.compactMap { key, entry in
            entry.localizations?[language]?.stringUnit.map { unit in (key: key, value: unit.value) }
        }
    }

    func pluralForms(in language: String) -> [(key: String, forms: [PluralCategory: String])] {
        strings.compactMap { key, entry in
            guard let plural = entry.localizations?[language]?.variations?.plural else { return nil }
            let forms = plural.reduce(into: [PluralCategory: String]()) { forms, item in
                if let category = PluralCategory(rawValue: item.key), let value = item.value.stringUnit?.value {
                    forms[category] = value
                }
            }
            return (key: key, forms: forms)
        }
    }
}
