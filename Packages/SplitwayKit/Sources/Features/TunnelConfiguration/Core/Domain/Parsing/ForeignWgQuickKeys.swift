enum ForeignWgQuickKeys {
    private static let unsupportedWgQuickKeys: Set<String> = [
        "preup", "postup", "predown", "postdown", "table", "saveconfig", "fwmark",
    ]

    private static let amneziaWGKeys: Set<String> = [
        "jc", "jmin", "jmax", "s1", "s2", "s3", "s4", "h1", "h2", "h3", "h4",
        "i1", "i2", "i3", "i4", "i5", "j1", "j2", "j3", "itime",
    ]

    static func issueKind(forUnrecognizedKey key: String) -> ConfigurationIssueKind {
        let lowercasedKey = key.lowercased()
        if unsupportedWgQuickKeys.contains(lowercasedKey) {
            return .unsupportedWgQuickKey(key)
        }
        if amneziaWGKeys.contains(lowercasedKey) {
            return .amneziaWGNotSupported(key)
        }
        return .unknownKey(key)
    }
}
