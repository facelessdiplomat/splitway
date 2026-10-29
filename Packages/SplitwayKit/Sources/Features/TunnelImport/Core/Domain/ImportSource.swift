public enum ImportSource: Sendable, Hashable {
    case text
    case file(name: String)
    case archiveEntry(archiveName: String, fileName: String)
}
