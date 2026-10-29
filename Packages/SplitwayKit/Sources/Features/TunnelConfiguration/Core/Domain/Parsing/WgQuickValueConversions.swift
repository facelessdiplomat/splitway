import SharedKernel

enum WgQuickValueConversions {
    static func privateKey(_ text: String) throws(ConfigurationValueError) -> PrivateKey {
        do { return try PrivateKey(base64Encoded: text) } catch { throw .key(error) }
    }

    static func publicKey(_ text: String) throws(ConfigurationValueError) -> PublicKey {
        do { return try PublicKey(base64Encoded: text) } catch { throw .key(error) }
    }

    static func presharedKey(_ text: String) throws(ConfigurationValueError) -> PresharedKey {
        do { return try PresharedKey(base64Encoded: text) } catch { throw .key(error) }
    }

    static func networks(_ text: String) throws(ConfigurationValueError) -> [IPNetwork] {
        var networks: [IPNetwork] = []
        for item in listItems(text) {
            do { networks.append(try IPNetwork(item)) } catch { throw .network(error) }
        }
        return networks
    }

    static func listenPort(_ text: String) throws(ConfigurationValueError) -> NetworkPort {
        do { return try NetworkPort(text) } catch { throw .port(error) }
    }

    static func mtu(_ text: String) throws(ConfigurationValueError) -> MTU {
        do { return try MTU(text) } catch { throw .mtu(error) }
    }

    static func persistentKeepalive(_ text: String) throws(ConfigurationValueError) -> PersistentKeepalive? {
        do { return try PersistentKeepalive.parse(text) } catch { throw .persistentKeepalive(error) }
    }

    static func endpoint(_ text: String) throws(ConfigurationValueError) -> Endpoint {
        do { return try Endpoint(text) } catch { throw .endpoint(error) }
    }

    static func dns(_ text: String) throws(ConfigurationValueError) -> DNSConfiguration {
        do { return try DNSConfiguration(entries: listItems(text)) } catch { throw .dns(error) }
    }

    private static func listItems(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { item in item.trimmingCharacters(in: .whitespaces) }
            .filter { item in !item.isEmpty }
    }
}
