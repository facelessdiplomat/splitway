import Foundation

struct ApplicationBundleFixture {
    private static let everyoneGroupIdentifier = "ABCDEFAB-CDEF-ABCD-EFAB-CDEF0000000C"

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

    func denyExecutionToEveryone(_ relativePath: String) throws {
        let path = root.appending(path: relativePath).path(percentEncoded: false)
        var everyone = uuid_t(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        guard uuid_parse(Self.everyoneGroupIdentifier, &everyone) == 0 else { throw CocoaError(.fileWriteUnknown) }
        var list: acl_t? = acl_init(1)
        defer { acl_free(UnsafeMutableRawPointer(list)) }
        var entry: acl_entry_t?
        var permissions: acl_permset_t?
        guard acl_create_entry(&list, &entry) == 0,
            acl_set_tag_type(entry, ACL_EXTENDED_DENY) == 0,
            acl_set_qualifier(entry, &everyone) == 0,
            acl_get_permset(entry, &permissions) == 0,
            acl_add_perm(permissions, ACL_EXECUTE) == 0,
            acl_set_permset(entry, permissions) == 0,
            acl_set_file(path, ACL_TYPE_EXTENDED, list) == 0
        else { throw CocoaError(.fileWriteUnknown) }
    }

    func makeSymbolicLink(_ relativePath: String, to destination: URL) throws {
        let link = root.appending(path: relativePath)
        try FileManager.default.createDirectory(
            at: link.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: destination)
    }

    func hideItem(_ relativePath: String) throws {
        let path = root.appending(path: relativePath).path(percentEncoded: false)
        guard lchflags(path, UInt32(UF_HIDDEN)) == 0 else { throw CocoaError(.fileWriteUnknown) }
    }

    func path(_ relativePath: String) -> String {
        let resolved = root.appending(path: relativePath).resolvingSymlinksInPath().path(percentEncoded: false)
        return resolved.hasSuffix("/") ? String(resolved.dropLast()) : resolved
    }
}
