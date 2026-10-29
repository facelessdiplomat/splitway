struct PackageResolution: Decodable {
    struct Pin: Decodable {
        let identity: String
    }

    let pins: [Pin]
}
