#if os(macOS)
    import ApplicationCatalog
    import Foundation

    struct CachedApplication: Sendable {
        let application: InstalledApplication
        let infoModificationDate: Date?
    }
#endif
