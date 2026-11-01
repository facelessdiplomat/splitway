import SystemExtension
import SystemExtensionTestSupport
import Testing

@Suite
struct DeactivateSystemExtensionUseCaseTests {
    @Test
    func removesTheExtension() async throws {
        let deactivator = ScriptedSystemExtensionDeactivator(events: [.completed])

        let outcome = try await DeactivateSystemExtensionUseCase(deactivator: deactivator).execute()

        #expect(outcome == .removed)
    }

    @Test
    func removesTheExtensionAfterARestartWhenTheSystemSaysSo() async throws {
        let deactivator = ScriptedSystemExtensionDeactivator(events: [.needsUserApproval, .willCompleteAfterReboot])

        let outcome = try await DeactivateSystemExtensionUseCase(deactivator: deactivator).execute()

        #expect(outcome == .removedAfterRestart)
    }

    @Test
    func reportsTheFailure() async {
        let deactivator = ScriptedSystemExtensionDeactivator(events: [.failed(.authorizationRequired)])

        await #expect(throws: SystemExtensionFailure.authorizationRequired) {
            try await DeactivateSystemExtensionUseCase(deactivator: deactivator).execute()
        }
    }

    @Test
    func treatsAnUnfinishedRequestAsUnknownFailure() async {
        let deactivator = ScriptedSystemExtensionDeactivator(events: [.needsUserApproval])

        await #expect(throws: SystemExtensionFailure.unknown) {
            try await DeactivateSystemExtensionUseCase(deactivator: deactivator).execute()
        }
    }
}
