import AppRouting
import AppRoutingTestSupport
import Testing
import TransparentProxy
import TransparentProxyTestSupport

@Suite
struct SourceApplicationResolverTests {
    private static let browserProcess = ProcessInstance(identifier: 4242, version: 7)
    private static let curlProcess = ProcessInstance(identifier: 5150, version: 2)
    private static let browserIdentity = CodeIdentity(
        signingIdentifier: "com.example.browser",
        teamIdentifier: FlowRoutingFixtures.browserTeam,
        executablePath: "/Applications/Browser.app/Contents/MacOS/Browser",
        isSignedByApple: false
    )
    private static let appleCurlIdentity = CodeIdentity(
        signingIdentifier: "com.apple.curl",
        teamIdentifier: nil,
        executablePath: "/usr/bin/curl",
        isSignedByApple: true
    )

    @Test
    func resolvesTheIdentifierTeamAndPathOfADeveloperSignedProcess() throws {
        let resolver = SourceApplicationResolver(
            reader: InMemoryCodeIdentityReader(identities: [Self.browserProcess: Self.browserIdentity]))

        let source = resolver.sourceApplication(of: try Self.token(of: Self.browserProcess))

        #expect(source == FlowRoutingFixtures.browser)
        #expect(ApplicationMatcher(try FlowRoutingFixtures.snapshot().applications).matches(source))
    }

    @Test
    func keepsTheIdentifierOfAppleSignedCodeWithoutATeam() throws {
        let resolver = SourceApplicationResolver(
            reader: InMemoryCodeIdentityReader(identities: [Self.curlProcess: Self.appleCurlIdentity]))

        let source = resolver.sourceApplication(of: try Self.token(of: Self.curlProcess))

        #expect(source.signingIdentifier == "com.apple.curl")
    }

    @Test
    func dropsTheSelfChosenIdentifierOfAdHocSignedCode() throws {
        let adHocCurl = CodeIdentity(
            signingIdentifier: "com.apple.curl",
            teamIdentifier: nil,
            executablePath: "/Users/someone/curl",
            isSignedByApple: false
        )
        let resolver = SourceApplicationResolver(
            reader: InMemoryCodeIdentityReader(identities: [Self.curlProcess: adHocCurl]))

        let source = resolver.sourceApplication(of: try Self.token(of: Self.curlProcess))

        #expect(
            source
                == SourceApplication(signingIdentifier: nil, teamIdentifier: nil, executablePath: "/Users/someone/curl")
        )
        #expect(!ApplicationMatcher(try FlowRoutingFixtures.snapshot().applications).matches(source))
    }

    @Test
    func readsTheCodeOfEachProcessOnlyOnce() throws {
        let reader = InMemoryCodeIdentityReader(identities: [Self.browserProcess: Self.browserIdentity])
        let resolver = SourceApplicationResolver(reader: reader)
        let auditToken = try Self.token(of: Self.browserProcess)

        let first = resolver.sourceApplication(of: auditToken)
        let second = resolver.sourceApplication(of: auditToken)

        #expect(first == second)
        #expect(reader.readCount == 1)
    }

    @Test
    func readsTheCodeAgainForANewProcessThatReusesTheIdentifier() throws {
        let reusedIdentifier = ProcessInstance(identifier: Self.browserProcess.identifier, version: 8)
        let reader = InMemoryCodeIdentityReader(identities: [
            Self.browserProcess: Self.browserIdentity, reusedIdentifier: Self.appleCurlIdentity,
        ])
        let resolver = SourceApplicationResolver(reader: reader)

        _ = resolver.sourceApplication(of: try Self.token(of: Self.browserProcess))
        let source = resolver.sourceApplication(of: try Self.token(of: reusedIdentifier))

        #expect(source.signingIdentifier == "com.apple.curl")
        #expect(reader.readCount == 2)
    }

    @Test
    func treatsAFlowWithoutAnAuditTokenAsUnknown() {
        let reader = InMemoryCodeIdentityReader()
        let resolver = SourceApplicationResolver(reader: reader)

        let source = resolver.sourceApplication(of: nil)

        #expect(source == SourceApplication(signingIdentifier: nil, teamIdentifier: nil, executablePath: nil))
        #expect(reader.readCount == 0)
    }

    @Test
    func remembersAProcessWhoseCodeCannotBeReadAsUnknown() throws {
        let reader = InMemoryCodeIdentityReader()
        let resolver = SourceApplicationResolver(reader: reader)
        let auditToken = try Self.token(of: Self.browserProcess)

        let first = resolver.sourceApplication(of: auditToken)
        _ = resolver.sourceApplication(of: auditToken)

        #expect(first == SourceApplication(signingIdentifier: nil, teamIdentifier: nil, executablePath: nil))
        #expect(reader.readCount == 1)
    }

    @Test
    func takesTheIdentifierOfTheFlowWhenTheCodeCannotBeRead() throws {
        let resolver = SourceApplicationResolver(reader: InMemoryCodeIdentityReader())
        let auditToken = try Self.token(of: Self.browserProcess)

        let source = resolver.sourceApplication(of: auditToken, signedAs: "com.example.browser")

        #expect(source == FlowRoutingFixtures.exitedBrowser)
    }

    @Test
    func prefersTheCodeOfTheProcessOverTheIdentifierOfTheFlow() throws {
        let resolver = SourceApplicationResolver(
            reader: InMemoryCodeIdentityReader(identities: [Self.browserProcess: Self.browserIdentity]))
        let auditToken = try Self.token(of: Self.browserProcess)

        let source = resolver.sourceApplication(of: auditToken, signedAs: "com.example.mail")

        #expect(source == FlowRoutingFixtures.browser)
    }

    @Test
    func keepsAFlowWithoutAnIdentifierUnknownWhenTheCodeCannotBeRead() throws {
        let resolver = SourceApplicationResolver(reader: InMemoryCodeIdentityReader())

        let source = resolver.sourceApplication(of: try Self.token(of: Self.browserProcess), signedAs: "")

        #expect(source == SourceApplication(signingIdentifier: nil, teamIdentifier: nil, executablePath: nil))
    }

    @Test
    func forgetsTheLeastRecentlyUsedProcessWhenTheCacheIsFull() throws {
        let thirdProcess = ProcessInstance(identifier: 6000, version: 1)
        let reader = InMemoryCodeIdentityReader(identities: [
            Self.browserProcess: Self.browserIdentity, Self.curlProcess: Self.appleCurlIdentity,
            thirdProcess: Self.browserIdentity,
        ])
        let resolver = SourceApplicationResolver(reader: reader, cacheCapacity: 2)

        for process in [Self.browserProcess, Self.curlProcess, Self.browserProcess, thirdProcess, Self.curlProcess] {
            _ = resolver.sourceApplication(of: try Self.token(of: process))
        }

        #expect(reader.readCount == 4)
    }

    private static func token(of process: ProcessInstance) throws -> AuditToken {
        try AuditToken.fixture(processIdentifier: process.identifier, version: process.version)
    }
}
