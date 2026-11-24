#if os(macOS)
    extension Duration {
        private static let millisecondsPerSecond: Int64 = 1_000
        private static let attosecondsPerMillisecond: Int64 = 1_000_000_000_000_000

        var wholeMilliseconds: Int32 {
            let (milliseconds, overflows) = components.seconds.multipliedReportingOverflow(
                by: Self.millisecondsPerSecond)
            guard !overflows else { return components.seconds < 0 ? .min : .max }
            guard milliseconds < Int64(Int32.max) else { return .max }
            return Int32(clamping: milliseconds + components.attoseconds / Self.attosecondsPerMillisecond)
        }
    }
#endif
