import AppRouting

public struct RefreshSelectedApplicationsUseCase: Sendable {
    private let resolve: ResolveApplicationIdentityUseCase

    public init(resolve: ResolveApplicationIdentityUseCase) {
        self.resolve = resolve
    }

    public func execute(_ selection: ApplicationSelection, installed: [InstalledApplication]) async
        -> ApplicationSelection
    {
        let installedByPath = Dictionary(installed.map { application in (application.path, application) }) { first, _ in
            first
        }
        var refreshed: [ApplicationIdentity] = []
        for identity in selection.applications {
            guard let application = installedByPath[identity.path], application.version != identity.bundleVersion,
                let rebuilt = try? await resolve.execute(for: application)
            else {
                refreshed.append(identity)
                continue
            }
            refreshed.append(rebuilt)
        }
        return ApplicationSelection(refreshed)
    }
}
