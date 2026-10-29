import SwiftUI

public struct TunnelLibraryCommands: Commands {
    private let addition: TunnelAdditionOptions
    private let navigation: TunnelLibraryNavigation

    public init(addition: TunnelAdditionOptions, navigation: TunnelLibraryNavigation) {
        self.addition = addition
        self.navigation = navigation
    }

    public var body: some Commands {
        CommandGroup(replacing: .newItem) {
            ForEach(addition.methods, id: \.self) { method in
                Button {
                    addition.add(method)
                } label: {
                    method.label
                }
                .keyboardShortcut(method.keyboardShortcut)
            }
        }
        CommandGroup(after: .toolbar) {
            Button {
                navigation.showLog()
            } label: {
                Text("Show Log", bundle: .module)
            }
            .keyboardShortcut("l", modifiers: [.command, .option])
        }
        #if os(iOS)
            CommandGroup(replacing: .appSettings) {
                Button {
                    navigation.showSettings?()
                } label: {
                    Text("Settings…", bundle: .module)
                }
                .keyboardShortcut(",")
                .disabled(navigation.showSettings == nil)
            }
        #endif
    }
}
