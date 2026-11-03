import AppKit
import ApplicationCatalog
import Foundation
import Synchronization

public final class FileSystemApplicationScanner: ApplicationBundleScanner {
    public static let standardDirectories: [URL] = [
        URL(filePath: "/Applications"),
        URL(filePath: "/Applications/Utilities"),
        URL(filePath: "/Applications/Setapp"),
        URL(filePath: "/System/Applications"),
        URL(filePath: "/System/Applications/Utilities"),
    ]
    private static let queue = DispatchQueue(label: "Splitway.ApplicationScanner", qos: .userInitiated)
    private static let bundleExtension = "app"
    private static let hiddenNamePrefix = "."

    private let directories: [URL]
    private let includesRunningApplications: Bool
    private let cache = Mutex<[String: CachedApplication]>([:])

    public init(directories: [URL] = standardDirectories, includesRunningApplications: Bool = true) {
        self.directories = directories
        self.includesRunningApplications = includesRunningApplications
    }

    public func installedApplications() async -> [InstalledApplication] {
        await withCheckedContinuation { continuation in
            Self.queue.async {
                continuation.resume(returning: self.scan())
            }
        }
    }

    private func scan() -> [InstalledApplication] {
        var seenPaths: Set<String> = []
        var applications: [InstalledApplication] = []
        for bundle in candidateBundles() {
            let path = bundle.canonicalFilePath
            guard seenPaths.insert(path).inserted, let application = cachedApplication(at: path) else { continue }
            applications.append(application)
        }
        return applications
    }

    private func candidateBundles() -> [URL] {
        let installed = directories.flatMap { directory in Self.bundles(in: directory, descendingOneLevel: true) }
        guard includesRunningApplications else { return installed }
        let running = NSWorkspace.shared.runningApplications
            .filter { application in application.activationPolicy == .regular }
            .compactMap(\.bundleURL)
        return installed + running
    }

    private func cachedApplication(at path: String) -> InstalledApplication? {
        let infoGeneration = Self.infoGeneration(ofBundleAt: path)
        if let infoGeneration, let cached = cache.withLock({ entries in entries[path] }),
            cached.infoGeneration == infoGeneration
        {
            return cached.application
        }
        guard let application = ApplicationBundleReader.application(at: path) else { return nil }
        cache.withLock { entries in
            entries[path] = CachedApplication(application: application, infoGeneration: infoGeneration)
        }
        return application
    }

    private static func infoGeneration(ofBundleAt path: String) -> Data? {
        let identifier = try? ApplicationBundleReader.infoFile(ofBundleAt: path)
            .resourceValues(forKeys: [.generationIdentifierKey]).generationIdentifier
        return identifier.flatMap { identifier in
            try? NSKeyedArchiver.archivedData(withRootObject: identifier, requiringSecureCoding: true)
        }
    }

    private static func bundles(in directory: URL, descendingOneLevel: Bool) -> [URL] {
        let items =
            (try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey]
            )) ?? []
        let visibleItems = items.filter { item in !item.lastPathComponent.hasPrefix(hiddenNamePrefix) }
        return visibleItems.flatMap { item -> [URL] in
            if item.pathExtension == bundleExtension {
                return [item]
            }
            let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
            return descendingOneLevel && isDirectory ? bundles(in: item, descendingOneLevel: false) : []
        }
    }
}
