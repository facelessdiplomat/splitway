import DesignSystemPresentation
import Settings
import SwiftUI

struct UninstallSection: View {
    let model: UninstallModel

    var body: some View {
        Section {
            Button(role: .destructive) {
                model.requestUninstall()
            } label: {
                Text("Uninstall Splitway…", bundle: .module)
            }
            .disabled(model.phase == .removing)
            if model.phase == .removing {
                ProgressView {
                    Text("Uninstalling…", bundle: .module)
                }
            }
        } footer: {
            Text(
                """
                Removes the tunnels with their keys, the VPN configurations, Splitway’s data and its network \
                extension.
                """,
                bundle: .module
            )
            .foregroundStyle(.supportingText)
        }
        .confirmationDialog(Text("Uninstall Splitway?", bundle: .module), isPresented: isConfirming) {
            Button(role: .destructive) {
                Task.immediate { await model.confirm() }
            } label: {
                Text("Uninstall", bundle: .module)
            }
        } message: {
            Text(
                """
                Splitway disconnects and removes its tunnels with their keys, the VPN configurations, its data \
                and the network extension. This can’t be undone.
                """,
                bundle: .module
            )
        }
        .alert(finishedTitle, isPresented: isFinished, presenting: report) { _ in
            Button {
                Task.immediate { await model.showInFinder() }
            } label: {
                Text("Show in Finder", bundle: .module)
            }
            Button(role: .cancel) {
                Task.immediate { await model.quit() }
            } label: {
                Text("Quit", bundle: .module)
            }
        } message: { report in
            UninstallReportMessage(report: report)
        }
    }

    private var report: UninstallReport? {
        guard case .finished(let report) = model.phase else { return nil }
        return report
    }

    private var finishedTitle: Text {
        report?.isComplete == false
            ? Text("Some Parts Weren’t Removed", bundle: .module) : Text("Splitway Is Uninstalled", bundle: .module)
    }

    private var isConfirming: Binding<Bool> {
        Binding {
            model.phase == .confirming
        } set: { isConfirming in
            if !isConfirming {
                model.cancel()
            }
        }
    }

    private var isFinished: Binding<Bool> {
        Binding {
            report != nil
        } set: { _ in
        }
    }
}
