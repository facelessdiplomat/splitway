import AppRouting
import Foundation
import Testing

@Suite
struct RoutingPolicyCodingTests {
    @Test
    func writesAFlatVersionedDocument() throws {
        let policy = RoutingPolicy(
            mode: .selectedApplications(ApplicationSelection([try Self.curl()])),
            whenTunnelUnavailable: .bypass
        )

        let json = try Self.sortedJSON(of: policy)

        #expect(json == Self.applicationsDocument)
    }

    private static let applicationsDocument =
        #"{"applications":[{"displayName":"curl","kind":"commandLineTool","path":"/usr/bin/curl","#
        + #""signingIdentifiers":[]}],"mode":"selectedApplications","schemaVersion":1,"#
        + #""whenTunnelUnavailable":"bypass"}"#

    @Test
    func writesTheSelectionOfAModeThatIsNotChosen() throws {
        let policy = RoutingPolicy(mode: .selectedApplications(ApplicationSelection([try Self.curl()])))
            .switchingMode(to: .allTraffic)

        let json = try Self.sortedJSON(of: policy)

        #expect(json == Self.rememberedApplicationsDocument)
    }

    @Test
    func readsTheSelectionOfAModeThatIsNotChosen() throws {
        let policy = try JSONDecoder().decode(
            RoutingPolicy.self,
            from: Data(Self.rememberedApplicationsDocument.utf8)
        )

        #expect(policy.mode == .allTraffic)
        #expect(policy.applicationSelection == ApplicationSelection([try Self.curl()]))
    }

    private static let rememberedApplicationsDocument =
        #"{"applications":[{"displayName":"curl","kind":"commandLineTool","path":"/usr/bin/curl","#
        + #""signingIdentifiers":[]}],"mode":"allTraffic","schemaVersion":1,"whenTunnelUnavailable":"block"}"#

    @Test
    func readsTheRetiredServicesModeAsAllTraffic() throws {
        let json = Data(
            (#"{"schemaVersion":1,"mode":"selectedServices","services":["telegram"],"#
                + #""whenTunnelUnavailable":"bypass"}"#).utf8
        )

        let policy = try JSONDecoder().decode(RoutingPolicy.self, from: json)

        #expect(policy == RoutingPolicy(mode: .allTraffic, whenTunnelUnavailable: .bypass))
    }

    @Test
    func ignoresTheServicesRememberedByTheRetiredMode() throws {
        let json = Data(
            (#"{"schemaVersion":1,"mode":"selectedApplications","services":["telegram"],"#
                + #""applications":[{"kind":"commandLineTool","displayName":"curl","path":"/usr/bin/curl"}]}"#).utf8
        )

        let policy = try JSONDecoder().decode(RoutingPolicy.self, from: json)

        #expect(policy == RoutingPolicy(mode: .selectedApplications(ApplicationSelection([try Self.curl()]))))
    }

    @Test(arguments: try samplePolicies())
    func roundTripsEveryMode(_ policy: RoutingPolicy) throws {
        let decoded = try JSONDecoder().decode(RoutingPolicy.self, from: JSONEncoder().encode(policy))

        #expect(decoded == policy)
    }

    @Test
    func defaultsMissingOptionalFieldsOfTheFirstSchema() throws {
        let json = Data(#"{"schemaVersion":1,"mode":"allTraffic"}"#.utf8)

        #expect(try JSONDecoder().decode(RoutingPolicy.self, from: json) == .default)
    }

    @Test(arguments: [
        #"{"schemaVersion":2,"mode":"allTraffic"}"#,
        #"{"schemaVersion":1,"mode":"selectedDomains"}"#,
        #"{"schemaVersion":1,"mode":"selectedApplications"}"#,
        #"{"mode":"allTraffic"}"#,
    ])
    func rejectsDocumentsItCannotTrust(_ json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RoutingPolicy.self, from: Data(json.utf8))
        }
    }

    private static func samplePolicies() throws -> [RoutingPolicy] {
        let application = try ApplicationIdentity(
            kind: .application,
            displayName: "Telegram",
            path: "/Applications/Telegram.app",
            signingIdentifiers: ["ru.keepcoder.Telegram"],
            teamIdentifier: "6N38VWS5BX"
        )
        let tool = try curl()
        return [
            .default,
            RoutingPolicy(mode: .selectedApplications(ApplicationSelection([application, tool]))),
            RoutingPolicy(mode: .selectedApplications(ApplicationSelection([tool])), whenTunnelUnavailable: .bypass),
            RoutingPolicy(mode: .selectedApplications(ApplicationSelection([tool]))).switchingMode(to: .allTraffic),
        ]
    }

    private static func curl() throws -> ApplicationIdentity {
        try ApplicationIdentity(kind: .commandLineTool, displayName: "curl", path: "/usr/bin/curl")
    }

    private static func sortedJSON(of policy: RoutingPolicy) throws -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(bytes: try encoder.encode(policy), encoding: .utf8)
    }
}
