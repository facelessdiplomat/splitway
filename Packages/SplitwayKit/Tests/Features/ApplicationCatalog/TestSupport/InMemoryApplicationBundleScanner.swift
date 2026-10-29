import ApplicationCatalog

public struct InMemoryApplicationBundleScanner: ApplicationBundleScanner {
    private let applications: [InstalledApplication]

    public init(applications: [InstalledApplication]) {
        self.applications = applications
    }

    public func installedApplications() async -> [InstalledApplication] {
        applications
    }
}
