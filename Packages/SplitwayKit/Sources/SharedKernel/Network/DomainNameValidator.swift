enum DomainNameValidator {
    static func normalizedName(from text: String) throws(DomainNameValidationError) -> String {
        let name = text.hasSuffix(".") ? String(text.dropLast()) : text
        guard !name.isEmpty else { throw .empty }
        guard name.utf8.allSatisfy(ASCIIByte.isASCII) else { throw .nonASCII }
        guard name.utf8.count <= DomainName.maximumLength else { throw .tooLong }
        let labels = name.split(separator: ".", omittingEmptySubsequences: false)
        for label in labels {
            try validate(label)
        }
        if let topLevelLabel = labels.last, topLevelLabel.utf8.allSatisfy(ASCIIByte.isDecimalDigit) {
            throw .numericTopLevelLabel
        }
        return name.lowercased()
    }

    private static func validate(_ label: Substring) throws(DomainNameValidationError) {
        guard !label.isEmpty else { throw .emptyLabel }
        guard label.utf8.count <= DomainName.maximumLabelLength else { throw .labelTooLong }
        guard label.utf8.allSatisfy(ASCIIByte.isHostnameCharacter) else { throw .invalidCharacter }
        guard label.first != "-", label.last != "-" else { throw .hyphenAtLabelEdge }
    }
}
