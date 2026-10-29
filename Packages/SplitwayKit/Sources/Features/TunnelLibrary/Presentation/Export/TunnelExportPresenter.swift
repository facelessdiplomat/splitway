import DesignSystemPresentation
import SwiftUI

struct TunnelExportPresenter: ViewModifier {
    let model: TunnelExportModel

    func body(content: Content) -> some View {
        content
            .alert(Text("Export private keys?", bundle: .module), isPresented: isConfirming) {
                Button {
                    Task.immediate { await model.confirmExport() }
                } label: {
                    Text("Export", bundle: .module)
                }
                Button(role: .cancel) {
                    model.cancelExport()
                } label: {
                    Text("Cancel", bundle: .module)
                }
            } message: {
                Text(
                    "The exported file contains private keys. Anyone who gets it can connect as you. Keep it safe.",
                    bundle: .module
                )
            }
            .fileExporter(
                isPresented: isExporting,
                document: model.document.map { document in ExportedDataDocument(contents: document.contents) },
                contentType: model.document?.kind.contentType ?? .data,
                defaultFilename: model.document?.fileName
            ) { result in
                model.finishExport(succeeded: (try? result.get()) != nil)
            }
            .modifier(TunnelExportProblemAlert(model: model))
    }

    private var isConfirming: Binding<Bool> {
        Binding {
            model.pendingExport != nil
        } set: { _ in
        }
    }

    private var isExporting: Binding<Bool> {
        Binding {
            model.document != nil
        } set: { isPresented in
            if !isPresented {
                model.finishExport(succeeded: false)
            }
        }
    }
}
