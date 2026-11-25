import AppRouting

public struct SaveCustomServiceUseCase: Sendable {
    private let repository: any CustomServiceRepository

    public init(repository: any CustomServiceRepository) {
        self.repository = repository
    }

    public func execute(_ draft: CustomServiceDraft) async throws(CustomServiceError) -> CustomService {
        let service = try CustomService(
            id: draft.identifier ?? ServiceIdentifier.forCustomService(),
            name: draft.name,
            rules: try draft.rules()
        )
        try await store(service)
        return service
    }

    private func store(_ service: CustomService) async throws(CustomServiceError) {
        do {
            var services = try await repository.loadCustomServices()
            if let index = services.firstIndex(where: { stored in stored.id == service.id }) {
                services[index] = service
            } else {
                services.append(service)
            }
            try await repository.saveCustomServices(services)
        } catch {
            throw .storageUnavailable
        }
    }
}
