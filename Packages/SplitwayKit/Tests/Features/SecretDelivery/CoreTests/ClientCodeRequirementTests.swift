import SecretDelivery
import Testing

@Suite
struct ClientCodeRequirementTests {
    @Test
    func acceptsOurAppSignedByOurTeamOrByTheAppStore() throws {
        let requirement = try ClientCodeRequirement(
            teamIdentifier: "AB12CD34EF", bundleIdentifier: "com.example.splitway")

        let expected =
            #"anchor apple generic and identifier "com.example.splitway""#
            + #" and (certificate leaf[field.1.2.840.113635.100.6.1.9] exists"#
            + #" or certificate leaf[subject.OU] = "AB12CD34EF")"#
        #expect(requirement.text == expected)
    }

    @Test(arguments: ["", "AB12CD34E", "AB12CD34EFG", "ab12cd34ef", #"AB12CD34E""#, "AB12 CD34E"])
    func rejectsATeamIdentifierThatIsNotTenCapitalLettersOrDigits(teamIdentifier: String) {
        #expect(throws: ClientCodeRequirementError.invalidTeamIdentifier) {
            try ClientCodeRequirement(teamIdentifier: teamIdentifier, bundleIdentifier: "com.example.splitway")
        }
    }

    @Test(arguments: [
        "", "com.example splitway", #"com.example"splitway"#, #"com.example.splitway" or anchor apple"#, ".com.example",
        "com..example", "com.example.",
    ])
    func rejectsABundleIdentifierThatCouldChangeTheRequirement(bundleIdentifier: String) {
        #expect(throws: ClientCodeRequirementError.invalidBundleIdentifier) {
            try ClientCodeRequirement(teamIdentifier: "AB12CD34EF", bundleIdentifier: bundleIdentifier)
        }
    }
}
