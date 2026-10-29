public protocol ApplicationBundleScanner: Sendable {
    func installedApplications() async -> [InstalledApplication]
}
