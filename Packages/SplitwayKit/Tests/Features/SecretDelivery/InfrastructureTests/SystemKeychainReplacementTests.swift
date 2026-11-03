import Security
import Testing
import TunnelLibrary

@testable import SecretDeliveryInfrastructure

@Suite
struct SystemKeychainReplacementTests {
    @Test
    func removesTheOldItemBeforeAddingTheNewOne() throws {
        var calls: [String] = []

        try SystemKeychainReplacement.replace(
            removingOldItem: {
                calls.append("remove")
                return errSecSuccess
            },
            addingNewItem: {
                calls.append("add")
                return errSecSuccess
            }
        )

        #expect(calls == ["remove", "add"])
    }

    @Test
    func addsTheNewItemWhenThereIsNoOldOne() throws {
        var isAdded = false

        try SystemKeychainReplacement.replace(
            removingOldItem: { errSecItemNotFound },
            addingNewItem: {
                isAdded = true
                return errSecSuccess
            }
        )

        #expect(isAdded)
    }

    @Test
    func failsWithoutAddingWhenTheOldItemCannotBeRemoved() {
        var isAdded = false

        #expect(throws: TunnelStorageError.unavailable) {
            try SystemKeychainReplacement.replace(
                removingOldItem: { errSecAuthFailed },
                addingNewItem: {
                    isAdded = true
                    return errSecSuccess
                }
            )
        }

        #expect(!isAdded)
    }

    @Test
    func failsWhenTheNewItemCannotBeAdded() {
        #expect(throws: TunnelStorageError.unavailable) {
            try SystemKeychainReplacement.replace(
                removingOldItem: { errSecSuccess },
                addingNewItem: { errSecDuplicateItem }
            )
        }
    }
}
