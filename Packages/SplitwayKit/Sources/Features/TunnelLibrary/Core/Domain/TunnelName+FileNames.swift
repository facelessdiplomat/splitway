import Foundation

extension TunnelName {
    private static let configurationFileExtension = "conf"
    private static let pathSeparator: Character = "/"
    private static let extensionSeparator: Character = "."

    public static func derived(fromFileName fileName: String) -> TunnelName? {
        let lastPathComponent = fileName.split(separator: pathSeparator).last.map(String.init) ?? fileName
        let baseName = removingConfigurationExtension(from: lastPathComponent)
        let readableName = String(baseName.trimmingCharacters(in: .whitespaces).prefix(maximumLength))
        return try? TunnelName(readableName)
    }

    private static func removingConfigurationExtension(from fileName: String) -> String {
        guard let separatorIndex = fileName.lastIndex(of: extensionSeparator),
            fileName[fileName.index(after: separatorIndex)...].lowercased() == configurationFileExtension
        else { return fileName }
        return String(fileName[..<separatorIndex])
    }
}
