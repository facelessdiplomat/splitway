enum ExportFileNaming {
    private static let fileExtension = ".conf"
    private static let unsafeCharacters: Set<Character> = ["/", "\\", ":"]
    private static let replacement: Character = "-"
    private static let firstDisambiguatingNumber = 2

    static func uniqueFileNames(for names: [TunnelName]) -> [String] {
        var takenKeys: Set<String> = []
        return names.map { name in
            let baseName = safeBaseName(of: name)
            var candidate = baseName
            var number = firstDisambiguatingNumber
            while !takenKeys.insert(candidate.lowercased()).inserted {
                candidate = "\(baseName) \(number)"
                number += 1
            }
            return candidate + fileExtension
        }
    }

    static func fileName(for name: TunnelName) -> String {
        safeBaseName(of: name) + fileExtension
    }

    private static func safeBaseName(of name: TunnelName) -> String {
        String(name.text.map { character in unsafeCharacters.contains(character) ? replacement : character })
    }
}
