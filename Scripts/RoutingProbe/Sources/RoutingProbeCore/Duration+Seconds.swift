extension Duration {
    private static let attosecondsPerSecond = 1e18

    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / Self.attosecondsPerSecond
    }
}
