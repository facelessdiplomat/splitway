enum PluralCategory: String {
    case one
    case few
    case many
    case other

    private static let russian = "ru"

    init(count: Int, language: String) {
        guard language == Self.russian else {
            self = count == 1 ? .one : .other
            return
        }
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        if lastDigit == 1, lastTwoDigits != 11 {
            self = .one
        } else if (2...4).contains(lastDigit), !(12...14).contains(lastTwoDigits) {
            self = .few
        } else {
            self = .many
        }
    }
}
