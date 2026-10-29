public enum UAPIResponseError: Error, Equatable, Sendable {
    case malformedResponse
    case deviceError(code: Int)
}
