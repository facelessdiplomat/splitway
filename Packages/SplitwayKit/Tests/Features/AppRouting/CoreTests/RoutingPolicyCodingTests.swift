import AppRouting
import Foundation
import Testing

@Suite
struct RoutingPolicyCodingTests {
    @Test
    func writesAFlatVersionedDocument() throws {
        let policy = RoutingPolicy(
            mode: .selectedServices(
                ServiceSelection([try ServiceIdentifier("telegram"), try ServiceIdentifier("youtube")])),
            whenTunnelUnavailable: .bypass
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let json = String(bytes: try encoder.encode(policy), encoding: .utf8)

        #expect(json == Self.servicesDocument)
    }

    private static let servicesDocument =
        #"{"mode":"selectedServices","schemaVersion":1,"#
        + #""services":["telegram","youtube"],"whenTunnelUnavailable":"bypass"}"#

    @Test
    func writesTheSelectionOfAModeThatIsNotChosen() throws {
        let policy = RoutingPolicy(mode: .selectedServices(ServiceSelection([try ServiceIdentifier("telegram")])))
            .switchingMode(to: .allTraffic)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let json = String(bytes: try encoder.encode(policy), encoding: .utf8)

        #expect(json == Self.rememberedServicesDocument)
    }

    @Test
    func readsTheSelectionOfAModeThatIsNotChosen() throws {
        let policy = try JSONDecoder().decode(RoutingPolicy.self, from: Data(Self.rememberedServicesDocument.utf8))

        #expect(policy.mode == .allTraffic)
        #expect(policy.serviceSelection == ServiceSelection([try ServiceIdentifier("telegram")]))
    }

    private static let rememberedServicesDocument =
        #"{"mode":"allTraffic","schemaVersion":1,"services":["telegram"],"whenTunnelUnavailable":"block"}"#

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
        #"{"schemaVersion":1,"mode":"selectedServices","services":["Not Valid"]}"#,
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
        let tool = try ApplicationIdentity(kind: .commandLineTool, displayName: "curl", path: "/usr/bin/curl")
        return [
            .default,
            RoutingPolicy(mode: .selectedApplications(ApplicationSelection([application, tool]))),
            RoutingPolicy(
                mode: .selectedServices(ServiceSelection([try ServiceIdentifier("telegram")])),
                whenTunnelUnavailable: .bypass
            ),
            RoutingPolicy(mode: .selectedApplications(ApplicationSelection([tool]))).switchingMode(to: .allTraffic),
        ]
    }
}
