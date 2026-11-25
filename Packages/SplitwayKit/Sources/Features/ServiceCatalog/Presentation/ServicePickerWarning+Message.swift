import SwiftUI

extension ServicePickerWarning {
    var message: Text {
        switch warning {
        case .emptySelection:
            Text("Choose at least one service, or no traffic will use the tunnel.", bundle: .module)
        case .networksOutsideAllowedIPs:
            Text(
                "Some networks of \(serviceName ?? "") are outside the tunnel’s Allowed IPs and won’t use the tunnel.",
                bundle: .module
            )
        case .allowedIPsWithoutDefaultRoute:
            Text(
                """
                The tunnel’s Allowed IPs don’t include 0.0.0.0/0, so the server may not pass the traffic of the \
                chosen services.
                """,
                bundle: .module
            )
        case .resolverOutsideAllowedIPs(let resolver):
            Text(
                """
                The DNS server \(resolver.description) is outside the tunnel’s Allowed IPs, so the domains of the \
                chosen services won’t resolve.
                """,
                bundle: .module
            )
        case .fakeNetworkConflict:
            Text(
                """
                The tunnel’s addresses overlap the range Splitway uses for services, so some addresses may not work.
                """,
                bundle: .module
            )
        }
    }
}
