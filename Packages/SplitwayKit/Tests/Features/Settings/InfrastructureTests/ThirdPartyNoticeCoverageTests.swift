import Settings
import SettingsInfrastructure
import Testing

@Suite
struct ThirdPartyNoticeCoverageTests {
    private static let dependenciesNotShippedInTheApp: Set<String> = [
        "go.uber.org/goleak", "golang.zx2c4.com/wintun",
    ]

    @Test
    func readsTheDependenciesOfEveryManifest() throws {
        let dependencies = try ProjectDependencyManifests(locatedAbove: #filePath).dependencies()

        #expect(
            dependencies.isSuperset(of: [
                "zipfoundation", ProjectDependencyManifests.goToolchain, "golang.zx2c4.com/wireguard",
                "golang.org/x/net",
            ]))
    }

    @Test
    func coversEveryDependencyShippedInTheApp() async throws {
        let dependencies = try ProjectDependencyManifests(locatedAbove: #filePath).dependencies()

        let uncovered = dependencies.subtracting(Self.dependenciesNotShippedInTheApp)
            .subtracting(try await Self.coveredDependencies())

        #expect(uncovered.isEmpty, "Add a notice to ThirdPartyNotices for \(uncovered.sorted())")
    }

    @Test
    func namesOnlyCurrentDependencies() async throws {
        let dependencies = try ProjectDependencyManifests(locatedAbove: #filePath).dependencies()

        let stale = try await Self.coveredDependencies().union(Self.dependenciesNotShippedInTheApp)
            .subtracting(dependencies)

        #expect(stale.isEmpty, "Not a dependency any more: \(stale.sorted())")
    }

    @Test
    func givesEveryNoticeItsLicenseAndCopyright() async throws {
        let notices = try await BundledThirdPartyNoticeSource().notices()

        #expect(!notices.isEmpty)
        for notice in notices {
            #expect(!notice.licenseName.isEmpty, "\(notice.name) has no license name")
            #expect(notice.text.contains("Copyright"), "\(notice.name) has no copyright line")
        }
    }

    private static func coveredDependencies() async throws -> Set<String> {
        Set(try await BundledThirdPartyNoticeSource().notices().flatMap(\.dependencies))
    }
}
