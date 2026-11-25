import DesignSystemPresentation
import ServiceCatalog
import SwiftUI

struct ServiceDetailView: View {
    let service: ServiceProfile
    let customServiceActions: CustomServiceActions?

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    ServiceIconView(icon: service.icon)
                    Text(verbatim: service.displayName)
                        .font(.headline)
                }
                KeyValueRow(Text("Category", bundle: .module), value: service.category.title)
            }
            Section {
                entries(service.rules.domainSuffixes.map(\.description))
            } header: {
                Text("Domains", bundle: .module)
            } footer: {
                Text("Subdomains are included.", bundle: .module)
            }
            Section {
                entries(service.rules.networks.map(\.description))
            } header: {
                Text("Networks", bundle: .module)
            }
            Section {
                Text(
                    """
                    Apps that look up names on their own or connect to built-in addresses can bypass the domain \
                    rules.
                    """,
                    bundle: .module
                )
            } header: {
                Text("Limitations", bundle: .module)
            }
            if let customServiceActions {
                Section {
                    Button(action: customServiceActions.edit) {
                        Text("Edit Service", bundle: .module)
                    }
                    Button(role: .destructive, action: customServiceActions.delete) {
                        Text("Delete Service", bundle: .module)
                    }
                }
            }
        }
        .navigationTitle(Text(verbatim: service.displayName))
    }

    @ViewBuilder
    private func entries(_ texts: [String]) -> some View {
        if texts.isEmpty {
            Text("None", bundle: .module)
                .foregroundStyle(.supportingText)
        } else {
            ForEach(texts, id: \.self) { text in
                Text(verbatim: text)
                    .textSelection(.enabled)
            }
        }
    }
}
