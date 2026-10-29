import TunnelLibrary

public struct ImportSelection: Sendable, Equatable {
    public let preview: ImportPreview
    private var selectedIndices: Set<Int>
    private var chosenNames: [Int: TunnelName] = [:]

    public init(preview: ImportPreview) {
        self.preview = preview
        selectedIndices = Set(
            preview.candidates.indices.filter { index in
                preview.candidates[index].isImportable && preview.candidates[index].alreadyImportedAs == nil
            }
        )
    }

    public var hasSelection: Bool {
        !selectedIndices.isEmpty
    }

    public var importNames: [Int: TunnelName] {
        var takenNames = preview.existingNames
        var names: [Int: TunnelName] = [:]
        for index in preview.candidates.indices where selectedIndices.contains(index) {
            let name = UniqueTunnelNameResolver.uniqueName(for: chosenName(of: index), takenNames: takenNames)
            takenNames.append(name)
            names[index] = name
        }
        return names
    }

    public var candidatesToImport: [ImportCandidate] {
        let names = importNames
        return preview.candidates.indices.compactMap { index in
            guard let name = names[index], let configuration = preview.candidates[index].configuration else {
                return nil
            }
            return ImportCandidate(proposedName: name, configuration: configuration)
        }
    }

    public func isSelected(_ index: Int) -> Bool {
        selectedIndices.contains(index)
    }

    public func chosenName(of index: Int) -> TunnelName {
        chosenNames[index] ?? preview.candidates[index].proposedName
    }

    public mutating func setSelected(_ isSelected: Bool, at index: Int) {
        guard preview.candidates.indices.contains(index), preview.candidates[index].isImportable else { return }
        if isSelected {
            selectedIndices.insert(index)
        } else {
            selectedIndices.remove(index)
        }
    }

    public mutating func rename(at index: Int, to name: TunnelName) {
        chosenNames[index] = name
    }
}
