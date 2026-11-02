import SwiftUI

struct ServiceRoutingExplanationView: View {
    let done: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(
                        """
                        Splitway sends only the DNS queries for the domains of the chosen services to the tunnel and \
                        answers them with addresses from a reserved range. Connections to those addresses go through \
                        the tunnel to the real servers. Networks that a service publishes go through the tunnel \
                        directly. Everything else uses your network as usual.
                        """,
                        bundle: .module
                    )
                } header: {
                    Text("How It Works", bundle: .module)
                }
                Section {
                    Text(
                        """
                        Apps that look up names on their own, for example over DNS over HTTPS, bypass the domain \
                        rules. Only the networks of the service reach the tunnel.
                        """,
                        bundle: .module
                    )
                    Text(
                        """
                        Apps that connect to built-in addresses use the tunnel only for addresses in the networks of \
                        the service.
                        """,
                        bundle: .module
                    )
                    Text(
                        """
                        Calls and video chats often connect to addresses that the app learns during the call and may \
                        bypass the tunnel.
                        """,
                        bundle: .module
                    )
                    Text("Services on shared content networks can be chosen only by domain.", bundle: .module)
                    Text(
                        """
                        After you turn off the VPN, apps connect directly again. Apps with their own address cache \
                        may keep using the reserved addresses for up to a minute.
                        """,
                        bundle: .module
                    )
                } header: {
                    Text("Limitations", bundle: .module)
                }
            }
            .navigationTitle(Text("Service Routing", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: done) {
                        Text("Done", bundle: .module)
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
    }
}
