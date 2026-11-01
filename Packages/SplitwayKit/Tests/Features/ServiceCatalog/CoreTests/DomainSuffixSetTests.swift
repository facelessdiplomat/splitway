import ServiceCatalog
import SharedKernel
import Testing

@Suite
struct DomainSuffixSetTests {
    @Test
    func dropsSuffixesCoveredByAShorterOne() throws {
        let set = DomainSuffixSet(try Self.domains("a.t.me", "t.me", "telegram.org", "cdn.telegram.org"))

        #expect(set.suffixes.map(\.description) == ["t.me", "telegram.org"])
    }

    @Test
    func listsSuffixesInAStableOrder() throws {
        let forward = DomainSuffixSet(try Self.domains("youtube.com", "googlevideo.com", "ytimg.com"))
        let backward = DomainSuffixSet(try Self.domains("ytimg.com", "googlevideo.com", "youtube.com"))

        #expect(forward == backward)
        #expect(forward.suffixes.map(\.description) == ["googlevideo.com", "youtube.com", "ytimg.com"])
    }

    @Test(arguments: [
        ("api.telegram.org", true), ("telegram.org", true), ("nottelegram.org", false), ("telegram.org.example", false),
    ])
    func matchesTheSuffixAndItsSubdomainsOnly(name: String, matches: Bool) throws {
        let set = DomainSuffixSet(try Self.domains("telegram.org"))

        #expect(set.contains(try DomainName(name)) == matches)
    }

    private static func domains(_ texts: String...) throws -> [DomainName] {
        try texts.map { text in try DomainName(text) }
    }
}
