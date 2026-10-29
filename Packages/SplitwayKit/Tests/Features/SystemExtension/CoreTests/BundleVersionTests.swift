import SystemExtension
import Testing

@Suite
struct BundleVersionTests {
    @Test(arguments: [("1", "1.0.0"), ("1.2", "1.2.0"), ("12.0.7", "12.0.7")])
    func treatsMissingComponentsAsZero(version: String, equivalent: String) throws {
        #expect(try #require(BundleVersion(version)) == (try #require(BundleVersion(equivalent))))
    }

    @Test
    func comparesComponentsAsNumbers() throws {
        #expect(try #require(BundleVersion("1.10")) > (try #require(BundleVersion("1.9"))))
        #expect(try #require(BundleVersion("2")) > (try #require(BundleVersion("1.99.99"))))
    }

    @Test(arguments: ["", "abc", "1..2", "1.-2", " 1"])
    func rejectsTextThatIsNotADottedNumber(_ text: String) {
        #expect(BundleVersion(text) == nil)
    }
}
