import Security
import TunnelLibrary

enum SystemKeychainReplacement {
    static func replace(
        removingOldItem removeOldItem: () -> OSStatus,
        addingNewItem addNewItem: () -> OSStatus
    ) throws(TunnelStorageError) {
        let removal = removeOldItem()
        guard removal == errSecSuccess || removal == errSecItemNotFound else { throw .unavailable }
        guard addNewItem() == errSecSuccess else { throw .unavailable }
    }
}
