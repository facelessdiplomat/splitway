import AppRouting
import Synchronization

public final class SourceApplicationResolver: Sendable {
    public static let standardCacheCapacity = 512
    public static let maximumLaunchDepth = 16
    private static let launchdProcessIdentifier: Int32 = 1
    private static let unknownSource = SourceApplication(
        signingIdentifier: nil, teamIdentifier: nil, executablePath: nil)

    private struct Caches {
        var sources: LeastRecentlyUsedCache<ProcessInstance, SourceApplication>
        var launchers: LeastRecentlyUsedCache<RunningProcess, SourceApplication>
    }

    private let reader: any CodeIdentityReader
    private let ancestry: any ProcessAncestryReader
    private let caches: Mutex<Caches>

    public init(
        reader: any CodeIdentityReader,
        ancestry: any ProcessAncestryReader,
        cacheCapacity: Int = standardCacheCapacity
    ) {
        self.reader = reader
        self.ancestry = ancestry
        caches = Mutex(
            Caches(
                sources: LeastRecentlyUsedCache(capacity: cacheCapacity),
                launchers: LeastRecentlyUsedCache(capacity: cacheCapacity)
            )
        )
    }

    public func sourceApplication(of auditToken: AuditToken?, signedAs claimedIdentifier: String? = nil)
        -> SourceApplication
    {
        let source = verifiedSource(of: auditToken)
        guard source.isUnidentified, let claimedIdentifier, !claimedIdentifier.isEmpty else { return source }
        return SourceApplication(
            signingIdentifier: nil,
            teamIdentifier: nil,
            executablePath: nil,
            unverifiedSigningIdentifier: claimedIdentifier,
            launchers: source.launchers
        )
    }

    private func verifiedSource(of auditToken: AuditToken?) -> SourceApplication {
        guard let auditToken else { return Self.unknownSource }
        return caches.withLock { caches in
            if let cached = caches.sources.value(for: auditToken.processInstance) {
                return cached
            }
            let identity = (try? reader.codeIdentity(of: auditToken))?.sourceApplication ?? Self.unknownSource
            let source = identity.launched(by: launchers(of: auditToken.processInstance.identifier, in: &caches))
            caches.sources.insert(source, for: auditToken.processInstance)
            return source
        }
    }

    private func launchers(of processIdentifier: Int32, in caches: inout Caches) -> [SourceApplication] {
        var launchers: [SourceApplication] = []
        var visited: Set<Int32> = [processIdentifier]
        var current = processIdentifier
        while launchers.count < Self.maximumLaunchDepth,
            let launcher = ancestry.launcher(of: current),
            launcher.identifier > Self.launchdProcessIdentifier,
            visited.insert(launcher.identifier).inserted
        {
            launchers.append(source(of: launcher, in: &caches))
            current = launcher.identifier
        }
        return launchers
    }

    private func source(of launcher: RunningProcess, in caches: inout Caches) -> SourceApplication {
        if let cached = caches.launchers.value(for: launcher) {
            return cached
        }
        let source = (try? ancestry.codeIdentity(of: launcher))?.sourceApplication ?? Self.unknownSource
        caches.launchers.insert(source, for: launcher)
        return source
    }
}

extension SourceApplication {
    fileprivate var isUnidentified: Bool {
        signingIdentifier == nil && teamIdentifier == nil && executablePath == nil
    }
}
