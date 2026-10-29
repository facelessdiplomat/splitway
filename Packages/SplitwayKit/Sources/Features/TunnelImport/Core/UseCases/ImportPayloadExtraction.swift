import Foundation

struct ImportPayloadExtraction {
    private(set) var configurations: [ExtractedConfiguration] = []
    private(set) var failures: [ImportSourceFailure] = []

    mutating func addText(_ text: String, from source: ImportSource) {
        configurations.append(ExtractedConfiguration(source: source, fileName: nil, text: text))
    }

    mutating func addFile(named fileName: String, contents: Data, from source: ImportSource) {
        guard let text = String(bytes: contents, encoding: .utf8) else {
            addFailure(.notText, of: source)
            return
        }
        configurations.append(ExtractedConfiguration(source: source, fileName: fileName, text: text))
    }

    mutating func addFailure(_ reason: ImportSourceFailureReason, of source: ImportSource) {
        failures.append(ImportSourceFailure(source: source, reason: reason))
    }
}
