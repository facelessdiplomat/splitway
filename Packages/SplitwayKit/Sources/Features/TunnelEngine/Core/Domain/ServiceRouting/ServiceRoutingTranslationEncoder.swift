import Foundation

public enum ServiceRoutingTranslationEncoder {
    public static func document(for translation: ServiceRoutingTranslation) throws(TunnelEngineError) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(ServiceRoutingTranslationDocument(translation)),
            let document = String(bytes: data, encoding: .utf8)
        else {
            throw .internalFailure
        }
        return document
    }
}
