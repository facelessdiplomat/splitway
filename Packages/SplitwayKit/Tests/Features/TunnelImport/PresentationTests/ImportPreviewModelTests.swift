import Foundation
import Testing
import TunnelConfigurationTestSupport
import TunnelImport
import TunnelImportPresentation

@MainActor
@Suite
struct ImportPreviewModelTests {
    private static let office = ImportPayload.file(name: "Office.conf", contents: Data(WgQuickFixtures.minimal.utf8))
    private static let home = ImportPayload.file(name: "Home.conf", contents: Data(WgQuickFixtures.full.utf8))
    private static let broken = ImportPayload.file(name: "Broken.conf", contents: Data("[Peer]\n".utf8))

    @Test
    func cannotImportWhenNothingIsSelected() async throws {
        let preview = try await ImportTestFlow().preview(of: [Self.office])
        let row = try #require(preview.rows.first)

        preview.setSelected(false, for: row)

        #expect(!preview.canImport)
    }

    @Test
    func showsWhichNameEachSelectedConfigurationGets() async throws {
        let preview = try await ImportTestFlow().preview(of: [Self.office, Self.office, Self.broken])

        #expect(preview.rows.map(\.importName) == ["Office", "Office 2", nil])
        #expect(preview.rows.map(\.importsUnderAnotherName) == [false, true, false])
        #expect(preview.rows.map(\.isImportable) == [true, true, false])
    }

    @Test
    func importsARenamedConfigurationUnderItsNewName() async throws {
        let flow = ImportTestFlow()
        let preview = try await flow.preview(of: [Self.office])

        preview.rename(try #require(preview.rows.first), to: "Prague")
        await preview.confirm()

        #expect(preview.rows.first?.name == "Prague")
        #expect(try await flow.storedNames() == ["Prague"])
    }

    @Test
    func keepsWhatTheUserTypesWhileTheNameIsInvalid() async throws {
        let preview = try await ImportTestFlow().preview(of: [Self.office])

        preview.rename(try #require(preview.rows.first), to: "   ")

        #expect(preview.rows.first?.name == "   ")
        #expect(preview.rows.first?.hasInvalidName == true)
        #expect(!preview.canImport)
    }

    @Test
    func keepsSpacesWhileTheUserTypes() async throws {
        let preview = try await ImportTestFlow().preview(of: [Self.office])

        preview.rename(try #require(preview.rows.first), to: "Home ")

        #expect(preview.rows.first?.name == "Home ")
        #expect(preview.rows.first?.importName == "Home")
        #expect(preview.canImport)
    }

    @Test
    func summarizesHowManyConfigurationsWereImported() async throws {
        let flow = ImportTestFlow()
        let preview = try await flow.preview(of: [Self.office, Self.home, Self.broken])

        await preview.confirm()

        #expect(preview.summary == ImportSummary(importedCount: 2, totalCount: 3))
        #expect(!preview.canImport)
        #expect(flow.importCount == 1)
    }
}
