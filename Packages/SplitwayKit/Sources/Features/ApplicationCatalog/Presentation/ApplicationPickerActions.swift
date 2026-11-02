import ApplicationCatalog

public struct ApplicationPickerActions: Sendable {
    let loadApplications: LoadInstalledApplicationsUseCase
    let resolveIdentity: ResolveApplicationIdentityUseCase
    let fileReader: any ApplicationFileReader
    let fileAccess: any ChosenFileAccess
    let iconLoader: any ApplicationIconLoader

    public init(
        loadApplications: LoadInstalledApplicationsUseCase,
        resolveIdentity: ResolveApplicationIdentityUseCase,
        fileReader: any ApplicationFileReader,
        fileAccess: any ChosenFileAccess,
        iconLoader: any ApplicationIconLoader
    ) {
        self.loadApplications = loadApplications
        self.resolveIdentity = resolveIdentity
        self.fileReader = fileReader
        self.fileAccess = fileAccess
        self.iconLoader = iconLoader
    }
}
