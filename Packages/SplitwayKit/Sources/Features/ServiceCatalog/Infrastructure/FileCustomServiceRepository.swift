import Foundation
import ServiceCatalog

public actor FileCustomServiceRepository: CustomServiceRepository {
    private static let documentFileName = "custom-services.json"

    private let directory: URL
    private let documentURL: URL

    public init(directory: URL) {
        self.directory = directory
        documentURL = directory.appending(path: Self.documentFileName)
    }

    public func loadCustomServices() async throws(ServiceCatalogError) -> [CustomService] {
        let data: Data
        do {
            data = try Data(contentsOf: documentURL)
        } catch CocoaError.fileReadNoSuchFile {
            return []
        } catch {
            throw .customServicesUnavailable
        }
        guard let document = try? JSONDecoder().decode(CustomServicesDocument.self, from: data),
            document.schemaVersion == CustomServicesDocument.currentSchemaVersion,
            let services = try? document.services.map({ entry in try entry.service() })
        else { throw .customServicesUnavailable }
        return services
    }

    public func saveCustomServices(_ services: [CustomService]) async throws(ServiceCatalogError) {
        let document = CustomServicesDocument(
            schemaVersion: CustomServicesDocument.currentSchemaVersion,
            services: services.map(CustomServiceEntry.init)
        )
        do {
            let data = try JSONEncoder().encode(document)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: documentURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            throw .customServicesUnavailable
        }
    }
}
