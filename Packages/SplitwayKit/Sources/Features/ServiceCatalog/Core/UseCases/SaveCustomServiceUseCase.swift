import AppRouting
import Foundation
import SharedKernel

public struct SaveCustomServiceUseCase: Sendable {
    private let repository: any CustomServiceRepository

    public init(repository: any CustomServiceRepository) {
        self.repository = repository
    }

    public func execute(_ draft: CustomServiceDraft) async throws(CustomServiceError) -> CustomService {
        let rules = try Self.rules(domains: draft.domains, networks: draft.networks)
        let service = try CustomService(
            id: draft.identifier ?? ServiceIdentifier.forCustomService(),
            name: draft.name,
            rules: rules
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

    private static func rules(domains: [String], networks: [String]) throws(CustomServiceError) -> ServiceRules {
        let domainNames = try entries(domains).map { text throws(CustomServiceError) in
            do {
                return try DomainName(text)
            } catch {
                throw .invalidDomain(text)
            }
        }
        let ipNetworks = try entries(networks).map { text throws(CustomServiceError) in
            do {
                return try IPNetwork(text)
            } catch {
                throw .invalidNetwork(text)
            }
        }
        do {
            return try ServiceRules(domainSuffixes: domainNames, networks: ipNetworks)
        } catch {
            throw .noRules
        }
    }

    private static func entries(_ texts: [String]) -> [String] {
        texts
            .map { text in text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { text in !text.isEmpty }
    }
}
