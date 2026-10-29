public enum CanonicalDecimalText {
    private static let maximumIntegerDigits = 9

    public static func isCanonical(_ text: Substring, maximumDigits: Int) -> Bool {
        let digits = text.utf8
        return (1...maximumDigits).contains(digits.count)
            && digits.allSatisfy(ASCIIByte.isDecimalDigit)
            && (digits.count == 1 || digits.first != ASCIIByte.zero)
    }

    public static func integerValue(of text: some StringProtocol) -> Int? {
        let digits = Substring(text)
        guard isCanonical(digits, maximumDigits: maximumIntegerDigits) else { return nil }
        return Int(digits)
    }
}
