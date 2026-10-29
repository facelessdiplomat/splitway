struct ThirdPartyNoticeManifestEntry: Decodable {
    let name: String
    let license: String
    let dependencies: [String]
    let textFile: String
}
