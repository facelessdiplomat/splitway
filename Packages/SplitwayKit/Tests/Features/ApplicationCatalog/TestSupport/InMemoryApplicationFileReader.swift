import ApplicationCatalog

public struct InMemoryApplicationFileReader: ApplicationFileReader {
    private let applicationsByPath: [String: InstalledApplication]

    public init(applications: [InstalledApplication] = []) {
        applicationsByPath = Dictionary(
            applications.map { application in (application.path, application) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    public func application(at path: String) async -> InstalledApplication? {
        applicationsByPath[path]
    }
}
