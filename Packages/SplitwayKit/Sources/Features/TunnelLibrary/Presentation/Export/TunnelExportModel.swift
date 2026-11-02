import Foundation
import Observation
import TunnelLibrary

@MainActor
@Observable
public final class TunnelExportModel {
    public private(set) var pendingExport: TunnelExportRequest?
    public private(set) var document: ExportedDocument?
    public private(set) var problem: TunnelExportProblem?
    private var skippedTunnels: [TunnelName] = []

    private let exportTunnels: ExportTunnelsUseCase
    private let abandonedCopies: any AbandonedExportCopies

    public init(exportTunnels: ExportTunnelsUseCase, abandonedCopies: any AbandonedExportCopies) {
        self.exportTunnels = exportTunnels
        self.abandonedCopies = abandonedCopies
    }

    public func requestExport(of id: TunnelIdentifier, named name: String) {
        pendingExport = .tunnel(id, name: name)
    }

    public func requestExportOfAllTunnels() {
        pendingExport = .allTunnels
    }

    public func cancelExport() {
        pendingExport = nil
    }

    public func confirmExport() async {
        guard let request = pendingExport else { return }
        pendingExport = nil
        do {
            switch request {
            case .tunnel(let id, _):
                let file = try await exportTunnels.exportConfiguration(of: id)
                skippedTunnels = []
                document = ExportedDocument(
                    fileName: file.fileName,
                    contents: Data(file.contents.utf8),
                    kind: .configuration
                )
            case .allTunnels:
                let archive = try await exportTunnels.exportAll()
                skippedTunnels = archive.skippedTunnels
                document = ExportedDocument(fileName: Self.archiveFileName, contents: archive.contents, kind: .archive)
            }
        } catch {
            problem = .failed
        }
    }

    public func finishExport(succeeded: Bool) async {
        let exportedContents = document?.contents
        document = nil
        guard succeeded else {
            if let exportedContents {
                await abandonedCopies.removeCopies(of: exportedContents)
            }
            return
        }
        if !skippedTunnels.isEmpty {
            problem = .skippedTunnels(skippedTunnels.map(\.description))
        }
        skippedTunnels = []
    }

    public func dismissProblem() {
        problem = nil
    }

    private static var archiveFileName: String {
        String(localized: "Splitway Tunnels", bundle: .module) + ".zip"
    }
}
