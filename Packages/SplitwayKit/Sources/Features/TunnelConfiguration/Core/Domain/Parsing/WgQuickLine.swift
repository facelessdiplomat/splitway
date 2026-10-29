struct WgQuickLine: Equatable {
    enum Content: Equatable {
        case sectionHeader(String)
        case entry(key: String, value: String)
        case malformed
    }

    let number: Int
    let content: Content
}
