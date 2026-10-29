import Foundation
import SharedKernel
import Testing

@Suite
struct DomainNameTests {
    private static let longestLabel = String(repeating: "a", count: DomainName.maximumLabelLength)

    @Test(arguments: [
        ("example.com", "example.com"),
        ("Example.COM.", "example.com"),
        ("vpn-01.prod.example.net", "vpn-01.prod.example.net"),
        ("xn--e1afmkfd.xn--p1ai", "xn--e1afmkfd.xn--p1ai"),
        ("localhost", "localhost"),
        ("t.me", "t.me"),
        ("a1.b2.c3", "a1.b2.c3"),
    ])
    func normalizesValidNames(input: String, normalized: String) throws {
        #expect(try DomainName(input).description == normalized)
    }

    @Test(arguments: ["", "."])
    func rejectsEmptyNames(_ text: String) {
        #expect(throws: DomainNameValidationError.empty) {
            try DomainName(text)
        }
    }

    @Test(arguments: ["a..b", ".example.com", "example.com.."])
    func rejectsEmptyLabels(_ text: String) {
        #expect(throws: DomainNameValidationError.emptyLabel) {
            try DomainName(text)
        }
    }

    @Test(arguments: ["-example.com", "example-.com", "a.-b.c"])
    func rejectsLabelsThatStartOrEndWithAHyphen(_ text: String) {
        #expect(throws: DomainNameValidationError.hyphenAtLabelEdge) {
            try DomainName(text)
        }
    }

    @Test(arguments: ["exa_mple.com", "exa mple.com", "example.com/path", "user@example.com"])
    func rejectsCharactersOutsideHostnames(_ text: String) {
        #expect(throws: DomainNameValidationError.invalidCharacter) {
            try DomainName(text)
        }
    }

    @Test(arguments: ["пример.рф", "exämple.com"])
    func rejectsNonASCIINamesThatAreNotPunycode(_ text: String) {
        #expect(throws: DomainNameValidationError.nonASCII) {
            try DomainName(text)
        }
    }

    @Test(arguments: ["1.2.3.4", "example.123"])
    func rejectsNumericTopLevelLabels(_ text: String) {
        #expect(throws: DomainNameValidationError.numericTopLevelLabel) {
            try DomainName(text)
        }
    }

    @Test
    func limitsLabelLength() throws {
        #expect(try DomainName(Self.longestLabel + ".com").description.hasPrefix(Self.longestLabel))
        #expect(throws: DomainNameValidationError.labelTooLong) {
            try DomainName(Self.longestLabel + "a.com")
        }
    }

    @Test
    func limitsTotalLength() throws {
        let threeLongestLabels = [Self.longestLabel, Self.longestLabel, Self.longestLabel].joined(separator: ".")
        let longestName = threeLongestLabels + "." + String(repeating: "b", count: 61)

        #expect(try DomainName(longestName).description.count == DomainName.maximumLength)
        #expect(throws: DomainNameValidationError.tooLong) {
            try DomainName(longestName + "b")
        }
    }

    @Test(arguments: [
        ("a.t.me", "t.me", true),
        ("t.me", "t.me", true),
        ("A.T.ME", "t.me", true),
        ("at.me", "t.me", false),
        ("me", "t.me", false),
        ("t.me.example.com", "t.me", false),
    ])
    func matchesTheDomainItselfAndItsSubdomains(name: String, domain: String, matches: Bool) throws {
        #expect(try DomainName(name).isSameOrSubdomain(of: DomainName(domain)) == matches)
    }

    @Test
    func roundTripsThroughCodableAsNormalizedText() throws {
        let names = [try DomainName("Example.COM")]

        let encoded = try JSONEncoder().encode(names)

        #expect(String(bytes: encoded, encoding: .utf8) == #"["example.com"]"#)
        #expect(try JSONDecoder().decode([DomainName].self, from: encoded) == names)
    }

    @Test
    func rejectsInvalidNamesWhenDecoding() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([DomainName].self, from: Data(#"["exa_mple.com"]"#.utf8))
        }
    }
}
