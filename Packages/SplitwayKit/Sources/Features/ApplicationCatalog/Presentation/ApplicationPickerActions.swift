import ApplicationCatalog

public struct ApplicationPickerActions: Sendable {
    let loadApplications: LoadInstalledApplicationsUseCase
    let resolveIdentity: ResolveApplicationIdentityUseCase
    let fileReader: any ApplicationFileReader
    let iconLoader: any ApplicationIconLoader

    public init(
        loadApplications: LoadInstalledApplicationsUseCase,
        resolveIdentity: ResolveApplicationIdentityUseCase,
        fileReader: any ApplicationFileReader,
        iconLoader: any ApplicationIconLoader
    ) {
        self.loadApplications = loadApplications
        self.resolveIdentity = resolveIdentity
        self.fileReader = fileReader
        self.iconLoader = iconLoader
    }
}
