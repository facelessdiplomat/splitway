#if os(macOS)
    import Foundation

    public enum NestedCodeEnumerator {
        private static let nestedBundleExtensions: Set<String> = ["app", "xpc", "appex"]
        private static let helperFolderName = "Helpers"
        private static let searchedFolders = [
            "Contents/Frameworks", "Contents/XPCServices", "Contents/Helpers", "Contents/Library/LoginItems",
            "Contents/PlugIns",
        ]
        private static let propertyKeys: Set<URLResourceKey> = [.isRegularFileKey, .isExecutableKey]

        public static func nestedCodePaths(inBundleAt path: String) -> [String] {
            let bundle = URL(filePath: path).resolvingSymlinksInPath()
            let paths = searchedFolders.flatMap { folder in nestedCode(in: bundle.appending(path: folder)) }
            return Set(paths).sorted()
        }

        private static func nestedCode(in folder: URL) -> [String] {
            guard
                let enumerator = FileManager.default.enumerator(
                    at: folder,
                    includingPropertiesForKeys: Array(propertyKeys),
                    options: [.skipsHiddenFiles]
                )
            else { return [] }
            var paths: [String] = []
            for case let item as URL in enumerator where isNestedCode(item) {
                paths.append(item.canonicalFilePath)
            }
            return paths
        }

        private static func isNestedCode(_ item: URL) -> Bool {
            if nestedBundleExtensions.contains(item.pathExtension) {
                return true
            }
            guard item.deletingLastPathComponent().lastPathComponent == helperFolderName,
                let values = try? item.resourceValues(forKeys: propertyKeys)
            else { return false }
            return values.isRegularFile == true && values.isExecutable == true
        }
    }
#endif
