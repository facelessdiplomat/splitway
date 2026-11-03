import Foundation

struct ImportPayloadExtractor: Sendable {
    private let archiveReader: any ArchiveReader

    init(archiveReader: any ArchiveReader) {
        self.archiveReader = archiveReader
    }

    func extract(_ payloads: [ImportPayload]) -> ImportPayloadExtraction {
        var extraction = ImportPayloadExtraction()
        for payload in payloads {
            switch payload {
            case .text(let text):
                extraction.addText(text, from: .text)
            case .file(let name, let contents):
                extractFile(named: name, contents: contents, into: &extraction)
            }
        }
        return extraction
    }

    private func extractFile(named name: String, contents: Data, into extraction: inout ImportPayloadExtraction) {
        switch ImportFileKind(fileName: name, contents: contents) {
        case .configurationText:
            extraction.addFile(named: name, contents: contents, from: .file(name: name))
        case .archive:
            extractArchive(named: name, contents: contents, into: &extraction)
        }
    }

    private func extractArchive(named name: String, contents: Data, into extraction: inout ImportPayloadExtraction) {
        let files: [ArchivedConfigurationFile]
        do {
            files = try archiveReader.configurationFiles(in: contents)
        } catch {
            extraction.addFailure(.archiveRejected(error), of: .file(name: name))
            return
        }
        guard !files.isEmpty else {
            extraction.addFailure(.noConfigurationsInArchive, of: .file(name: name))
            return
        }
        for file in files {
            let source = ImportSource.archiveEntry(archiveName: name, fileName: file.fileName)
            extraction.addFile(named: file.fileName, contents: file.contents, from: source)
        }
    }
}
