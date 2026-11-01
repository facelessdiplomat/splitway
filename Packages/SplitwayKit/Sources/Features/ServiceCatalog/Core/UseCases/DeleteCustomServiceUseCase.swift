import AppRouting

public struct DeleteCustomServiceUseCase: Sendable {
    private let repository: any CustomServiceRepository

    public init(repository: any CustomServiceRepository) {
        self.repository = repository
    }

    public func execute(_ identifier: ServiceIdentifier) async throws(CustomServiceError) {
        do {
            let services = try await repository.loadCustomServices()
            try await repository.saveCustomServices(services.filter { service in service.id != identifier })
        } catch {
            throw .storageUnavailable
        }
    }
}
