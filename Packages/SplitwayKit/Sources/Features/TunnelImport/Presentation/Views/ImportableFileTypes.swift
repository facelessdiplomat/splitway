import TunnelConfigurationPresentation
import UniformTypeIdentifiers

enum ImportableFileTypes {
    private static let configurationFileExtension = "conf"

    static func types(
        declaredForExtension declaredTypes: (String) -> [UTType] = { fileExtension in
            UTType.types(tag: fileExtension, tagClass: .filenameExtension, conformingTo: nil)
        }
    ) -> [UTType] {
        var types: [UTType] = [.wireGuardConfiguration]
        for type in declaredTypes(configurationFileExtension) + [.zip, .plainText] where !types.contains(type) {
            types.append(type)
        }
        return types
    }
}
