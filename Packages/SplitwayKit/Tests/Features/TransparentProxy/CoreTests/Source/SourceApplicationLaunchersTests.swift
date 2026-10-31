import AppRouting
import AppRoutingTestSupport
import Testing
import TransparentProxy
import TransparentProxyTestSupport

@Suite
struct SourceApplicationLaunchersTests {
    private static let gitProcess = ProcessInstance(identifier: 5000, version: 1)
    private static let otherGitProcess = ProcessInstance(identifier: 5001, version: 1)
    private static let shell = RunningProcess(identifier: 4000, startTime: 100)
    private static let browser = RunningProcess(identifier: 4242, startTime: 50)
    private static let launchd = RunningProcess(identifier: 1, startTime: 1)
    private static let gitIdentity = CodeIdentity(
        signingIdentifier: "com.apple.git", teamIdentifier: nil, executablePath: "/usr/bin/git", isSignedByApple: true)
    private static let shellIdentity = CodeIdentity(
        signingIdentifier: "com.apple.zsh", teamIdentifier: nil, executablePath: "/bin/zsh", isSignedByApple: true)
    private static let browserIdentity = CodeIdentity(
        signingIdentifier: "com.example.browser",
        teamIdentifier: FlowRoutingFixtures.browserTeam,
        executablePath: "/Applications/Browser.app/Contents/MacOS/Browser",
        isSignedByApple: false
    )
    private static let unknown = SourceApplication(signingIdentifier: nil, teamIdentifier: nil, executablePath: nil)

    @Test
    func resolvesTheProcessesThatLaunchedTheSourceNearestFirstWithoutLaunchd() throws {
        let resolver = Self.resolver(
            launchers: [5000: Self.shell, 4000: Self.browser, 4242: Self.launchd],
            identities: [Self.shell: Self.shellIdentity, Self.browser: Self.browserIdentity]
        )

        let source = resolver.sourceApplication(of: try Self.token(of: Self.gitProcess))

        #expect(source.launchers == [FlowRoutingFixtures.appleShell, FlowRoutingFixtures.browser])
        #expect(ApplicationMatcher(try FlowRoutingFixtures.snapshot().applications).matches(source))
    }

    @Test
    func stopsAtALoopInTheProcessTree() throws {
        let resolver = Self.resolver(
            launchers: [5000: Self.shell, 4000: RunningProcess(identifier: 5000, startTime: 1)],
            identities: [Self.shell: Self.shellIdentity]
        )

        let source = resolver.sourceApplication(of: try Self.token(of: Self.gitProcess))

        #expect(source.launchers == [FlowRoutingFixtures.appleShell])
    }

    @Test
    func stopsAfterTheMaximumLaunchDepth() throws {
        let depth = SourceApplicationResolver.maximumLaunchDepth + 4
        var launchers: [Int32: RunningProcess] = [:]
        for level in 0..<Int32(depth) {
            launchers[5000 + level] = RunningProcess(identifier: 5001 + level, startTime: UInt64(level))
        }
        let resolver = Self.resolver(launchers: launchers, identities: [:])

        let source = resolver.sourceApplication(of: try Self.token(of: Self.gitProcess))

        #expect(source.launchers.count == SourceApplicationResolver.maximumLaunchDepth)
    }

    @Test
    func walksPastALauncherWhoseCodeCannotBeRead() throws {
        let resolver = Self.resolver(
            launchers: [5000: Self.shell, 4000: Self.browser],
            identities: [Self.browser: Self.browserIdentity]
        )

        let source = resolver.sourceApplication(of: try Self.token(of: Self.gitProcess))

        #expect(source.launchers == [Self.unknown, FlowRoutingFixtures.browser])
    }

    @Test
    func readsTheCodeOfALauncherOnlyOnce() throws {
        let ancestry = InMemoryProcessAncestryReader(
            launchers: [5000: Self.shell, 5001: Self.shell, 4000: Self.browser],
            identities: [Self.shell: Self.shellIdentity, Self.browser: Self.browserIdentity]
        )
        let resolver = Self.resolver(ancestry: ancestry)

        let first = resolver.sourceApplication(of: try Self.token(of: Self.gitProcess))
        let second = resolver.sourceApplication(of: try Self.token(of: Self.otherGitProcess))

        #expect(first.launchers == second.launchers)
        #expect(ancestry.identityReadCount == 2)
    }

    @Test
    func readsTheCodeAgainForALauncherThatStartedLater() throws {
        let restartedShell = RunningProcess(identifier: Self.shell.identifier, startTime: 900)
        let ancestry = InMemoryProcessAncestryReader(
            launchers: [5000: Self.shell, 5001: restartedShell],
            identities: [Self.shell: Self.shellIdentity, restartedShell: Self.browserIdentity]
        )
        let resolver = Self.resolver(ancestry: ancestry)

        let first = resolver.sourceApplication(of: try Self.token(of: Self.gitProcess))
        let second = resolver.sourceApplication(of: try Self.token(of: Self.otherGitProcess))

        #expect(first.launchers == [FlowRoutingFixtures.appleShell])
        #expect(second.launchers == [FlowRoutingFixtures.browser])
    }

    @Test
    func keepsTheLaunchersOfACodeThatClaimsAnIdentifier() throws {
        let ancestry = InMemoryProcessAncestryReader(
            launchers: [5000: Self.browser], identities: [Self.browser: Self.browserIdentity])
        let resolver = SourceApplicationResolver(reader: InMemoryCodeIdentityReader(), ancestry: ancestry)

        let source = resolver.sourceApplication(of: try Self.token(of: Self.gitProcess), signedAs: "com.example.tool")

        #expect(source.unverifiedSigningIdentifier == "com.example.tool")
        #expect(source.launchers == [FlowRoutingFixtures.browser])
    }

    private static func resolver(launchers: [Int32: RunningProcess], identities: [RunningProcess: CodeIdentity])
        -> SourceApplicationResolver
    {
        resolver(ancestry: InMemoryProcessAncestryReader(launchers: launchers, identities: identities))
    }

    private static func resolver(ancestry: InMemoryProcessAncestryReader) -> SourceApplicationResolver {
        SourceApplicationResolver(
            reader: InMemoryCodeIdentityReader(identities: [gitProcess: gitIdentity, otherGitProcess: gitIdentity]),
            ancestry: ancestry
        )
    }

    private static func token(of process: ProcessInstance) throws -> AuditToken {
        try AuditToken.fixture(processIdentifier: process.identifier, version: process.version)
    }
}
