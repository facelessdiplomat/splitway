import DesignSystemPresentation
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct LogExportPresenter: ViewModifier {
    let model: LogViewerModel

    func body(content: Content) -> some View {
        content.fileExporter(
            isPresented: isExporting,
            document: model.exportedText.map { text in ExportedDataDocument(contents: Data(text.utf8)) },
            contentType: .plainText,
            defaultFilename: String(localized: "Splitway Log", bundle: .module)
        ) { result in
            let succeeded = (try? result.get()) != nil
            Task.immediate { await model.finishExport(succeeded: succeeded) }
        }
    }

    private var isExporting: Binding<Bool> {
        Binding {
            model.exportedText != nil
        } set: { isPresented in
            if !isPresented {
                Task.immediate { await model.finishExport(succeeded: false) }
            }
        }
    }
}
