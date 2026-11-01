public struct DeactivateSystemExtensionUseCase: Sendable {
    private let deactivator: any SystemExtensionDeactivator

    public init(deactivator: any SystemExtensionDeactivator) {
        self.deactivator = deactivator
    }

    public func execute() async throws(SystemExtensionFailure) -> SystemExtensionRemoval {
        for await event in deactivator.requestDeactivation() {
            switch event {
            case .needsUserApproval:
                continue
            case .completed:
                return .removed
            case .willCompleteAfterReboot:
                return .removedAfterRestart
            case .failed(let failure):
                throw failure
            }
        }
        throw .unknown
    }
}
