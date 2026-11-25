import Foundation

struct CatalogFixtureFile {
    let url: URL

    init(contents: String) throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory.appending(path: "catalog.json")
        try Data(contents.utf8).write(to: url)
    }

    static func document(schemaVersion: Int = 1, services: String) -> String {
        #"{"schemaVersion": \#(schemaVersion), "services": [\#(services)]}"#
    }

    static func entry(id: String = "telegram", domains: String = #"["telegram.org", "t.me"]"#) -> String {
        #"""
        {"id": "\#(id)", "displayName": "Telegram", "category": "messaging", "monogram": "T", "tint": "#229ED9",
         "domainSuffixes": \#(domains), "ipv4Networks": ["91.108.4.0/22"], "ipv6Networks": ["2001:b28:f23d::/48"],
         "notes": "https://core.telegram.org/resources/cidr.txt"}
        """#
    }
}
