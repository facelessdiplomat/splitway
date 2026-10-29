import Foundation

public struct LoadInstalledApplicationsUseCase: Sendable {
    private let scanner: any ApplicationBundleScanner

    public init(scanner: any ApplicationBundleScanner) {
        self.scanner = scanner
    }

    public func execute() async -> [InstalledApplication] {
        await scanner.installedApplications().sorted { first, second in
            first.name.localizedStandardCompare(second.name) == .orderedAscending
        }
    }
}
