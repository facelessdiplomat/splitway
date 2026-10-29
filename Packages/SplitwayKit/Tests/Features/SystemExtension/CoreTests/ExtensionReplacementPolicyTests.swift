import SystemExtension
import Testing

@Suite
struct ExtensionReplacementPolicyTests {
    @Test(arguments: [
        ("7", "8", ExtensionReplacementAction.replace),
        ("8", "8", .keep),
        ("8", "7", .replace),
    ])
    func keepsTheExtensionInStepWithTheApp(active: String, bundled: String, action: ExtensionReplacementAction) {
        #expect(ExtensionReplacementPolicy.action(replacing: active, with: bundled) == action)
    }

    @Test
    func replacesAnExtensionWhoseVersionCannotBeRead() {
        #expect(ExtensionReplacementPolicy.action(replacing: "unknown", with: "8") == .replace)
    }
}
