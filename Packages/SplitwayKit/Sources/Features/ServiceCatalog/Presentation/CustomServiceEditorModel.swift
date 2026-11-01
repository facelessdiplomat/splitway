import AppRouting
import Foundation
import Observation
import ServiceCatalog

@MainActor
@Observable
public final class CustomServiceEditorModel: Identifiable {
    private static let entrySeparators = CharacterSet(charactersIn: ",\n")

    public var name: String
    public var domainsText: String
    public var networksText: String
    public private(set) var isSaving = false
    public private(set) var saveFailure: CustomServiceError?
    public let isNewService: Bool

    private let identifier: ServiceIdentifier?
    private let saveService: SaveCustomServiceUseCase
    private let didSave: @MainActor (CustomService) -> Void

    public init(save: SaveCustomServiceUseCase, didSave: @escaping @MainActor (CustomService) -> Void) {
        name = ""
        domainsText = ""
        networksText = ""
        isNewService = true
        identifier = nil
        saveService = save
        self.didSave = didSave
    }

    public init(
        editing profile: ServiceProfile,
        save: SaveCustomServiceUseCase,
        didSave: @escaping @MainActor (CustomService) -> Void
    ) {
        let draft = CustomServiceDraft(editing: profile)
        name = draft.name
        domainsText = draft.domains.joined(separator: "\n")
        networksText = draft.networks.joined(separator: "\n")
        isNewService = false
        identifier = profile.id
        saveService = save
        self.didSave = didSave
    }

    public var invalidDomains: [String] {
        draft.problems.compactMap { problem in
            guard case .invalidDomain(let entry) = problem else { return nil }
            return entry
        }
    }

    public var invalidNetworks: [String] {
        draft.problems.compactMap { problem in
            guard case .invalidNetwork(let entry) = problem else { return nil }
            return entry
        }
    }

    public var canSave: Bool {
        !isSaving && draft.problems.isEmpty
    }

    public func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            didSave(try await saveService.execute(draft))
        } catch {
            saveFailure = error
        }
    }

    public func dismissSaveFailure() {
        saveFailure = nil
    }

    private var draft: CustomServiceDraft {
        CustomServiceDraft(
            editing: identifier,
            name: name,
            domains: domainsText.components(separatedBy: Self.entrySeparators),
            networks: networksText.components(separatedBy: Self.entrySeparators)
        )
    }
}
