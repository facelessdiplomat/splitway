import Foundation

extension ServiceIdentifier {
    private static let customServicePrefix = "custom-"

    public static func forCustomService() -> ServiceIdentifier {
        ServiceIdentifier(validatedValue: customServicePrefix + UUID().uuidString.lowercased())
    }
}
