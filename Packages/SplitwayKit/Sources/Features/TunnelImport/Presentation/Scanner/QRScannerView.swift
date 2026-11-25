#if os(iOS)
    import PhotosUI
    import SwiftUI
    import VisionKit

    struct QRScannerView: View {
        let model: QRScannerModel
        let close: @MainActor () -> Void
        @State private var selectedPhoto: PhotosPickerItem?

        var body: some View {
            QRScannerContent(model: model)
                .navigationTitle(Text("Scan QR Code", bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            close()
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label {
                            Text("Choose Photo", bundle: .module)
                        } icon: {
                            Image(systemName: "photo.on.rectangle")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .task { await model.prepare(isCameraScanningSupported: DataScannerViewController.isSupported) }
                .onChange(of: selectedPhoto) { _, photo in
                    guard let photo else { return }
                    selectedPhoto = nil
                    Task.immediate { await model.importPhoto(try? await photo.loadTransferable(type: Data.self)) }
                }
                .modifier(QRPhotoProblemAlert(model: model))
        }
    }
#endif
