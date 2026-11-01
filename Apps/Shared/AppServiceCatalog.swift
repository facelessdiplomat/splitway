import AppRouting
import Foundation
import ServiceCatalogPresentation

#if os(iOS)
    import ServiceCatalog
    import ServiceCatalogInfrastructure
#endif

struct AppServiceCatalog {
    let picker: ServicePickerActions?
    let loadServiceNames: @Sendable () async -> [ServiceIdentifier: String]

    init(storageDirectory: URL) {
        #if os(iOS)
            let bundled = BundledServiceCatalogRepository.bundled
            let custom = FileCustomServiceRepository(directory: storageDirectory)
            let catalog = LoadServiceCatalogUseCase(bundled: bundled, custom: custom)
            picker = ServicePickerActions(bundled: bundled, custom: custom)
            loadServiceNames = { (try? await catalog.execute())?.displayNames ?? [:] }
        #else
            picker = nil
            loadServiceNames = { [:] }
        #endif
    }
}
