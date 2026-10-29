import Settings

extension ThirdPartyNotice {
    public static func fixture(named name: String, licenseName: String = "MIT") -> ThirdPartyNotice {
        ThirdPartyNotice(
            name: name,
            licenseName: licenseName,
            dependencies: [name.lowercased()],
            text: "Copyright \(name) authors"
        )
    }
}
