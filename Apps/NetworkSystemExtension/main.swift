import Foundation
import NetworkExtension

autoreleasepool {
    NEProvider.startSystemExtensionMode()
}

let secretDelivery = ExtensionSecretDelivery(bundle: .main)
secretDelivery?.start()

dispatchMain()
