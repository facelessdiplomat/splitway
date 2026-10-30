#if os(macOS)
    import ApplicationCatalog
    import Foundation

    public struct FileSystemApplicationFileReader: ApplicationFileReader {
        private static let queue = DispatchQueue(label: "Splitway.ApplicationFileReader", qos: .userInitiated)
        private static let bundleExtension = "app"

        public init() {}

        public func application(at path: String) async -> InstalledApplication? {
            await withCheckedContinuation { continuation in
                Self.queue.async {
                    continuation.resume(returning: Self.readApplication(at: path))
                }
            }
        }

        private static func readApplication(at path: String) -> InstalledApplication? {
            let canonicalPath = URL(filePath: path).canonicalFilePath
            let file = URL(filePath: canonicalPath)
            if file.pathExtension == bundleExtension {
                return ApplicationBundleReader.application(at: canonicalPath)
            }
            guard isExecutableRegularFile(file) else { return nil }
            return InstalledApplication(
                kind: .commandLineTool,
                name: file.lastPathComponent,
                bundleIdentifier: nil,
                path: canonicalPath,
                version: nil
            )
        }

        private static func isExecutableRegularFile(_ file: URL) -> Bool {
            let values = try? file.resourceValues(forKeys: [.isRegularFileKey, .isExecutableKey])
            return values?.isRegularFile == true && values?.isExecutable == true
        }
    }
#endif
