#if os(macOS)
    import Foundation

    struct ApplicationBundleFixture {
        let root: URL

        init() {
            root = FileManager.default.temporaryDirectory.appending(
                path: "ApplicationCatalogTests-\(UUID().uuidString)")
        }

        func remove() {
            try? FileManager.default.removeItem(at: root)
        }

        @discardableResult
        func makeApplication(_ relativePath: String, bundleIdentifier: String, version: String) throws -> URL {
            let bundle = root.appending(path: relativePath)
            let contents = bundle.appending(path: "Contents")
            try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
            let info: [String: String] = [
                "CFBundleIdentifier": bundleIdentifier,
                "CFBundleShortVersionString": version,
                "CFBundlePackageType": "APPL",
            ]
            let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            try data.write(to: contents.appending(path: "Info.plist"))
            return bundle
        }

        func makeDirectory(_ relativePath: String) throws {
            try FileManager.default.createDirectory(
                at: root.appending(path: relativePath),
                withIntermediateDirectories: true
            )
        }

        func makeExecutable(_ relativePath: String) throws {
            let file = root.appending(path: relativePath)
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("#!/bin/sh\n".utf8).write(to: file)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755], ofItemAtPath: file.path(percentEncoded: false))
        }

        func makeSymbolicLink(_ relativePath: String, to destination: URL) throws {
            try FileManager.default.createSymbolicLink(
                at: root.appending(path: relativePath), withDestinationURL: destination)
        }

        func path(_ relativePath: String) -> String {
            let resolved = root.appending(path: relativePath).resolvingSymlinksInPath().path(percentEncoded: false)
            return resolved.hasSuffix("/") ? String(resolved.dropLast()) : resolved
        }
    }
#endif
