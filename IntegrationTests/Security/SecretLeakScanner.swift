import Foundation

struct SecretLeakScanner {
    private struct Needle {
        let description: String
        let bytes: Data
    }

    private let needles: [Needle]

    init(secrets: [String: Data]) {
        needles = secrets.sorted { $0.key < $1.key }
            .flatMap { name, key in
                [
                    Needle(description: "\(name) in base64", bytes: Data(key.base64EncodedString().utf8)),
                    Needle(description: "\(name) in hex", bytes: Data(Self.hex(of: key).utf8)),
                    Needle(description: "\(name) as raw bytes", bytes: key),
                ]
            }
    }

    func leaks(inFilesUnder directory: URL) -> [String] {
        guard let items = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey])
        else { return [] }
        var leaks: [String] = []
        for case let file as URL in items {
            guard (try? file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
                let contents = try? Data(contentsOf: file, options: .mappedIfSafe)
            else { continue }
            leaks += found(in: contents).map { needle in "\(needle) in \(file.path(percentEncoded: false))" }
        }
        return leaks
    }

    func leaks(in defaults: UserDefaults, named name: String) -> [String] {
        leaks(inPropertyList: defaults.dictionaryRepresentation(), at: name)
    }

    func leaks(in text: String, named name: String) -> [String] {
        found(in: Data(text.utf8)).map { needle in "\(needle) in \(name)" }
    }

    private func leaks(inPropertyList value: Any, at path: String) -> [String] {
        switch value {
        case let text as String:
            found(in: Data(text.utf8)).map { needle in "\(needle) in \(path)" }
        case let contents as Data:
            found(in: contents).map { needle in "\(needle) in \(path)" }
        case let array as [Any]:
            array.enumerated().flatMap { index, element in leaks(inPropertyList: element, at: "\(path)[\(index)]") }
        case let dictionary as [String: Any]:
            dictionary.flatMap { key, element in leaks(inPropertyList: element, at: "\(path).\(key)") }
        default:
            []
        }
    }

    private func found(in contents: Data) -> [String] {
        needles.filter { needle in contents.range(of: needle.bytes) != nil }.map(\.description)
    }

    private static func hex(of key: Data) -> String {
        key.map { byte in String(format: "%02x", byte) }.joined()
    }
}
