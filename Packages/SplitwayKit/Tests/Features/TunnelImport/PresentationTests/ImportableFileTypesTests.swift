import Testing
import TunnelConfigurationPresentation
import UniformTypeIdentifiers

@testable import TunnelImportPresentation

@Suite
struct ImportableFileTypesTests {
    @Test
    func acceptsTheTypeAnotherAppDeclaresForConfigurationFiles() {
        let typeOfAnotherApp = UTType(importedAs: "com.example.proxy-profile")

        let types = ImportableFileTypes.types { fileExtension in fileExtension == "conf" ? [typeOfAnotherApp] : [] }

        #expect(types.contains(typeOfAnotherApp))
        #expect(types.contains(.wireGuardConfiguration))
    }

    @Test
    func listsEveryTypeOnce() {
        let types = ImportableFileTypes.types { _ in [.wireGuardConfiguration, .plainText] }

        #expect(Set(types) == [.wireGuardConfiguration, .zip, .plainText])
        #expect(types.count == 3)
    }

    @Test
    func acceptsTheTypeThisSystemAssignsToConfigurationFiles() throws {
        let systemType = try #require(UTType(filenameExtension: "conf"))

        #expect(ImportableFileTypes.types().contains(systemType))
    }
}
