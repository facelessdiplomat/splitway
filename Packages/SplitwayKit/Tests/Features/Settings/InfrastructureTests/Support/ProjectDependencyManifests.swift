import Foundation

struct ProjectDependencyManifests {
    static let goToolchain = "go"

    private static let projectSpecification = "project.yml"
    private static let swiftPackageResolutions = [
        "Packages/SplitwayKit/Package.resolved",
        "Packages/TunnelCore/Package.resolved",
    ]
    private static let goModules = ["Packages/TunnelCore/go/go.mod"]
    private static let remotePackagePrefix = "url:"

    private let root: URL

    init(locatedAbove filePath: String) throws {
        var directory = URL(filePath: filePath).deletingLastPathComponent()
        while !FileManager.default.fileExists(atPath: directory.appending(path: Self.projectSpecification).path()) {
            let parent = directory.deletingLastPathComponent()
            guard parent != directory else { throw CocoaError(.fileNoSuchFile) }
            directory = parent
        }
        root = directory
    }

    func dependencies() throws -> Set<String> {
        let swiftPackages = try Self.swiftPackageResolutions.flatMap(swiftPackageIdentities(in:))
        let goDependencies = try Self.goModules.flatMap(goDependencies(in:))
        return try Set(swiftPackages + goDependencies + remotePackageIdentities())
    }

    private func swiftPackageIdentities(in path: String) throws -> [String] {
        let resolution = try JSONDecoder().decode(PackageResolution.self, from: Data(contentsOf: url(of: path)))
        return resolution.pins.map(\.identity)
    }

    private func goDependencies(in path: String) throws -> [String] {
        let module = GoModuleFile(contents: try String(contentsOf: url(of: path), encoding: .utf8))
        return module.requiredModules + (module.declaresGoVersion ? [Self.goToolchain] : [])
    }

    private func remotePackageIdentities() throws -> [String] {
        let specification = try String(contentsOf: url(of: Self.projectSpecification), encoding: .utf8)
        return specification.split(whereSeparator: \.isNewline)
            .map { line in line.trimmingCharacters(in: .whitespaces) }
            .filter { line in line.hasPrefix(Self.remotePackagePrefix) }
            .compactMap { line in
                URL(string: line.dropFirst(Self.remotePackagePrefix.count).trimmingCharacters(in: .whitespaces))
            }
            .map { url in url.deletingPathExtension().lastPathComponent.lowercased() }
    }

    private func url(of path: String) -> URL {
        root.appending(path: path)
    }
}
