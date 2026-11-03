import TunnelConfiguration
import TunnelLibrary

struct ImportCandidateEvaluator {
    private let existingTunnels: [Tunnel]
    private let fallbackName: TunnelName
    private var takenNames: [TunnelName]

    init(library: TunnelLibrarySnapshot, fallbackName: TunnelName) {
        existingTunnels = library.tunnels
        takenNames = library.tunnels.map(\.name) + library.unreadableRecords.map(\.name)
        self.fallbackName = fallbackName
    }

    mutating func evaluate(_ extracted: ExtractedConfiguration) -> ImportPreviewCandidate {
        let parsingResult = WgQuickConfigurationParser.parse(extracted.text)
        let proposedName =
            extracted.fileName.flatMap(TunnelName.derived(fromFileName:)) ?? fallbackName
        let uniqueName = UniqueTunnelNameResolver.uniqueName(for: proposedName, takenNames: takenNames)
        if parsingResult.configuration != nil {
            takenNames.append(uniqueName)
        }
        return ImportPreviewCandidate(
            source: extracted.source,
            proposedName: proposedName,
            uniqueName: uniqueName,
            configuration: parsingResult.configuration,
            issues: parsingResult.issues,
            alreadyImportedAs: existingTunnel(configuredAs: parsingResult.configuration)?.name
        )
    }

    private func existingTunnel(configuredAs configuration: TunnelConfiguration?) -> Tunnel? {
        guard let configuration else { return nil }
        return existingTunnels.first { tunnel in tunnel.configuration == configuration }
    }
}
