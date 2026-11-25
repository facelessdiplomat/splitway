import XCTest

final class LabelTranslationsTests: XCTestCase {
    private let russian = LabelTranslations(language: "ru", catalogs: LocalizedLabels.catalogs)
    private let english = LabelTranslations(language: "en", catalogs: LocalizedLabels.catalogs)

    func testOffersEveryRussianTranslationOfALabel() {
        let labels = russian.matching("Edit Tunnel")

        XCTAssertEqual(Set(labels), ["Изменить туннель", "Изменение туннеля"])
    }

    func testKeepsLabelsAsTheyAreInEnglish() {
        XCTAssertEqual(english.matching("Edit Tunnel"), ["Edit Tunnel"])
    }

    func testKeepsTextThatHasNoTranslation() {
        XCTAssertEqual(russian.matching("Office Prague"), ["Office Prague"])
    }

    func testFallsBackToSystemLabelsTheCatalogsLack() {
        XCTAssertTrue(russian.matching("More").contains("Еще"))
    }

    func testPicksTheRussianPluralForm() {
        let format = "%lld services selected"

        XCTAssertEqual(russian.counted(format, count: 1), ["Выбран 1 сервис"])
        XCTAssertEqual(russian.counted(format, count: 2), ["Выбрано 2 сервиса"])
        XCTAssertEqual(russian.counted(format, count: 5), ["Выбрано 5 сервисов"])
        XCTAssertEqual(russian.counted(format, count: 21), ["Выбран 21 сервис"])
    }

    func testPicksTheEnglishPluralForm() {
        XCTAssertEqual(english.counted("%lld services selected", count: 2), ["2 services selected"])
    }

    func testFlagsEnglishTextThatHasARussianTranslation() {
        XCTAssertTrue(russian.isUntranslatedEnglish("Tunnels"))
        XCTAssertFalse(russian.isUntranslatedEnglish("Туннели"))
        XCTAssertFalse(russian.isUntranslatedEnglish("Splitway"))
        XCTAssertFalse(english.isUntranslatedEnglish("Tunnels"))
    }

    func testFollowsTheRussianPluralRules() {
        let expected: [Int: PluralCategory] = [
            1: .one, 2: .few, 4: .few, 5: .many, 11: .many, 12: .many, 14: .many, 21: .one, 22: .few, 25: .many,
            111: .many,
        ]

        for (count, category) in expected {
            XCTAssertEqual(PluralCategory(count: count, language: "ru"), category, "\(count)")
        }
    }

    func testFollowsTheEnglishPluralRules() {
        XCTAssertEqual(PluralCategory(count: 1, language: "en"), .one)
        XCTAssertEqual(PluralCategory(count: 2, language: "en"), .other)
    }
}
