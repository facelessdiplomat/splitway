import Foundation

extension LocalizedStringResource {
    static func moduleResource(_ value: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(value, bundle: .atURL(Bundle.module.bundleURL))
    }
}
