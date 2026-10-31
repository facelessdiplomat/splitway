import AppRouting
import Synchronization

public final class SourceApplicationResolver: Sendable {
    public static let standardCacheCapacity = 512
    private static let unknownSource = SourceApplication(
        signingIdentifier: nil, teamIdentifier: nil, executablePath: nil)

    private let reader: any CodeIdentityReader
    private let sources: Mutex<LeastRecentlyUsedCache<ProcessInstance, SourceApplication>>

    public init(reader: any CodeIdentityReader, cacheCapacity: Int = standardCacheCapacity) {
        self.reader = reader
        sources = Mutex(LeastRecentlyUsedCache(capacity: cacheCapacity))
    }

    public func sourceApplication(of auditToken: AuditToken?, signedAs claimedIdentifier: String? = nil)
        -> SourceApplication
    {
        let source = verifiedSource(of: auditToken)
        guard source == Self.unknownSource, let claimedIdentifier, !claimedIdentifier.isEmpty else { return source }
        return SourceApplication(
            signingIdentifier: nil,
            teamIdentifier: nil,
            executablePath: nil,
            unverifiedSigningIdentifier: claimedIdentifier
        )
    }

    private func verifiedSource(of auditToken: AuditToken?) -> SourceApplication {
        guard let auditToken else { return Self.unknownSource }
        return sources.withLock { cache in
            if let cached = cache.value(for: auditToken.processInstance) {
                return cached
            }
            let source = (try? reader.codeIdentity(of: auditToken))?.sourceApplication ?? Self.unknownSource
            cache.insert(source, for: auditToken.processInstance)
            return source
        }
    }
}
