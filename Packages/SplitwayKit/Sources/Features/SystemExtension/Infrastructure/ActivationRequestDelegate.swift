import Foundation
import Synchronization
import SystemExtension
import SystemExtensions

final class ActivationRequestDelegate: NSObject, OSSystemExtensionRequestDelegate, Sendable {
    private let continuation: AsyncStream<SystemExtensionActivationEvent>.Continuation
    private let isKeepingActiveExtension = Mutex(false)

    init(continuation: AsyncStream<SystemExtensionActivationEvent>.Continuation) {
        self.continuation = continuation
    }

    func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension ext: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        switch ExtensionReplacementPolicy.action(replacing: existing.bundleVersion, with: ext.bundleVersion) {
        case .replace:
            return .replace
        case .keep:
            isKeepingActiveExtension.withLock { isKeeping in isKeeping = true }
            return .cancel
        }
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        continuation.yield(.needsUserApproval)
    }

    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        continuation.yield(result == .willCompleteAfterReboot ? .willCompleteAfterReboot : .completed)
        continuation.finish()
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: any Error) {
        let keptActiveExtension = isKeepingActiveExtension.withLock { isKeeping in isKeeping }
        if keptActiveExtension, SystemExtensionErrorMapping.isCancellation(error) {
            continuation.yield(.completed)
        } else {
            continuation.yield(.failed(SystemExtensionErrorMapping.failure(for: error)))
        }
        continuation.finish()
    }
}
