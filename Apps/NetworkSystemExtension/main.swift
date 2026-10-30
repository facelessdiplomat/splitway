import Foundation
import NetworkExtension

autoreleasepool {
    NEProvider.startSystemExtensionMode()
}

let secretsSpikeListener = SecretsSpikeListener(bundle: .main)
secretsSpikeListener?.start()

dispatchMain()
