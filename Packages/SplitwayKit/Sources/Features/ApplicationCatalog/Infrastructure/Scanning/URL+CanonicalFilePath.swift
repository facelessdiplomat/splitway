#if os(macOS)
    import Foundation

    extension URL {
        private static let pathSeparator: Character = "/"

        var canonicalFilePath: String {
            var path = Substring(resolvingSymlinksInPath().path(percentEncoded: false))
            while path.count > 1, path.last == Self.pathSeparator {
                path = path.dropLast()
            }
            return String(path)
        }
    }
#endif
