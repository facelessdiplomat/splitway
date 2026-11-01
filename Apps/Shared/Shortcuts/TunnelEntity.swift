import AppIntents
import Foundation
import TunnelLibrary

struct TunnelEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Tunnel")
    }

    static var defaultQuery: TunnelEntityQuery {
        TunnelEntityQuery()
    }

    let id: UUID
    let name: String

    init(record: TunnelRecord) {
        id = record.id.rawValue
        name = record.name.description
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    var tunnelIdentifier: TunnelIdentifier {
        TunnelIdentifier(id)
    }
}
