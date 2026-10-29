import Foundation
import Testing
import TunnelConfigurationTestSupport
import TunnelImport
import TunnelLibrary

@Suite
struct ImportSelectionTests {
    @Test
    func selectsEveryImportableNewConfigurationByDefault() async throws {
        let environment = ImportTestEnvironment()
        try await environment.storeTunnel(named: "Office", fixture: WgQuickFixtures.minimal)
        let preview = try await environment.prepareImport().execute([
            .file(name: "Home.conf", contents: Data(WgQuickFixtures.full.utf8)),
            .file(name: "Broken.conf", contents: Data("[Peer]\n".utf8)),
            .file(name: "Copy.conf", contents: Data(WgQuickFixtures.minimal.utf8)),
        ])

        let selection = ImportSelection(preview: preview)

        #expect(preview.candidates.indices.map(selection.isSelected) == [true, false, false])
    }

    @Test
    func neverSelectsAConfigurationThatDoesNotParse() async throws {
        let preview = try await ImportTestEnvironment().prepareImport().execute([
            .file(name: "Broken.conf", contents: Data("[Peer]\n".utf8))
        ])
        var selection = ImportSelection(preview: preview)

        selection.setSelected(true, at: 0)

        #expect(!selection.isSelected(0))
        #expect(!selection.hasSelection)
    }

    @Test
    func namesTheSelectionUniquelyAgainstTheLibrary() async throws {
        let environment = ImportTestEnvironment()
        try await environment.storeTunnel(named: "Office", fixture: WgQuickFixtures.minimal)
        let preview = try await environment.prepareImport().execute([
            .file(name: "Office.conf", contents: Data(WgQuickFixtures.full.utf8)),
            .file(name: "office.conf", contents: Data(WgQuickFixtures.multiplePeers.utf8)),
        ])

        let selection = ImportSelection(preview: preview)

        #expect(selection.importNames[0]?.description == "Office 2")
        #expect(selection.importNames[1]?.description == "office 3")
    }

    @Test
    func freesANameWhenItsCandidateIsDeselected() async throws {
        let preview = try await ImportTestEnvironment().prepareImport().execute([
            .file(name: "Office.conf", contents: Data(WgQuickFixtures.minimal.utf8)),
            .file(name: "Office.conf", contents: Data(WgQuickFixtures.full.utf8)),
        ])
        var selection = ImportSelection(preview: preview)

        selection.setSelected(false, at: 0)

        #expect(selection.importNames[0] == nil)
        #expect(selection.importNames[1]?.description == "Office")
    }

    @Test
    func importsARenamedCandidateUnderItsNewName() async throws {
        let preview = try await ImportTestEnvironment().prepareImport().execute([
            .file(name: "Office.conf", contents: Data(WgQuickFixtures.minimal.utf8))
        ])
        var selection = ImportSelection(preview: preview)

        selection.rename(at: 0, to: try TunnelName("Prague"))

        #expect(selection.chosenName(of: 0).description == "Prague")
        #expect(selection.candidatesToImport.map(\.proposedName.description) == ["Prague"])
    }

    @Test
    func importsOnlyTheSelectedCandidates() async throws {
        let preview = try await ImportTestEnvironment().prepareImport().execute([
            .file(name: "Office.conf", contents: Data(WgQuickFixtures.minimal.utf8)),
            .file(name: "Home.conf", contents: Data(WgQuickFixtures.full.utf8)),
        ])
        var selection = ImportSelection(preview: preview)

        selection.setSelected(false, at: 0)

        #expect(selection.candidatesToImport.map(\.proposedName.description) == ["Home"])
        #expect(selection.hasSelection)
    }
}
