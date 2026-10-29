enum CanonicalDecimalText {
    static func isCanonical(_ text: Substring, maximumDigits: Int) -> Bool {
        let digits = text.utf8
        return (1...maximumDigits).contains(digits.count)
            && digits.allSatisfy(ASCIIByte.isDecimalDigit)
            && (digits.count == 1 || digits.first != ASCIIByte.zero)
    }
}
