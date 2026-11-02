import ApplicationCatalog

public struct InMemoryApplicationFileReader: ApplicationFileReader {
    private let applicationsByPath: [String: InstalledApplication]
    private let access: InMemoryChosenFileAccess?

    public init(
        applications: [InstalledApplication] = [],
        readableWhileOpenIn access: InMemoryChosenFileAccess? = nil
    ) {
        applicationsByPath = Dictionary(
            applications.map { application in (application.path, application) },
            uniquingKeysWith: { first, _ in first }
        )
        self.access = access
    }

    public func application(at path: String) async -> InstalledApplication? {
        if let access, !access.isOpen(path) {
            return nil
        }
        return applicationsByPath[path]
    }
}
