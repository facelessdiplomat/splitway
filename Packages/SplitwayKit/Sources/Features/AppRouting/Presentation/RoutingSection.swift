import AppRouting
import DesignSystemPresentation
import SwiftUI

public struct RoutingSection: View {
    private let model: RoutingSectionModel
    private let excludesPrivateNetworks: Binding<Bool>?

    public init(model: RoutingSectionModel, excludesPrivateNetworks: Binding<Bool>?) {
        self.model = model
        self.excludesPrivateNetworks = excludesPrivateNetworks
    }

    public var body: some View {
        Section {
            Picker(selection: mode) {
                ForEach(model.availableModes, id: \.self) { mode in
                    mode.title.tag(mode)
                }
            } label: {
                Text("Through the tunnel", bundle: .module)
            }
            RoutingSelectionSummary(model: model)
            if let excludesPrivateNetworks {
                Toggle(isOn: excludesPrivateNetworks) {
                    Text("Exclude private networks", bundle: .module)
                }
            }
            if model.offersUnavailableTunnelChoice {
                Toggle(isOn: blocksWhenTunnelUnavailable) {
                    Text("Block traffic when the tunnel is unavailable", bundle: .module)
                }
            }
        } header: {
            Text("Routing", bundle: .module)
                .foregroundStyle(.supportingText)
        }
    }

    private var mode: Binding<RoutingModeKind> {
        Binding {
            model.selectedMode
        } set: { mode in
            model.selectMode(mode)
        }
    }

    private var blocksWhenTunnelUnavailable: Binding<Bool> {
        Binding {
            model.blocksWhenTunnelUnavailable
        } set: { blocks in
            model.setBlocksWhenTunnelUnavailable(blocks)
        }
    }
}
