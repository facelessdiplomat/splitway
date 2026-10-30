public enum ResolverConfiguration {
    private static let nameserverKeyword = "nameserver"

    public static func firstNameserver(in text: String) -> String? {
        for line in text.split(whereSeparator: \.isNewline) {
            let fields = line.split(whereSeparator: \.isWhitespace)
            if fields.count >= 2, fields[0] == nameserverKeyword {
                return String(fields[1])
            }
        }
        return nil
    }
}
