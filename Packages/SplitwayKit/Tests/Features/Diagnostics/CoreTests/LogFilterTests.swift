import Diagnostics
import Foundation
import Testing

@Suite
struct LogFilterTests {
    private static let moment = Date(timeIntervalSince1970: 1_793_268_900)
    private static let engineError = LogEntry(date: moment, level: .error, source: .engine, message: "Handshake failed")
    private static let appInfo = LogEntry(date: moment, level: .info, source: .application, message: "Tunnel saved")
    private static let extensionDebug = LogEntry(
        date: moment, level: .debug, source: .tunnelExtension, message: "Network path changed")

    @Test
    func ordersLevelsBySeverity() {
        #expect(LogLevel.allCases.sorted() == [.debug, .info, .warning, .error])
    }

    @Test
    func showsEverythingByDefault() {
        let filter = LogFilter()

        #expect([Self.engineError, Self.appInfo, Self.extensionDebug].allSatisfy(filter.matches))
    }

    @Test
    func keepsEntriesAtOrAboveTheMinimumLevel() {
        let filter = LogFilter(minimumLevel: .info)

        #expect(filter.matches(Self.engineError))
        #expect(filter.matches(Self.appInfo))
        #expect(!filter.matches(Self.extensionDebug))
    }

    @Test
    func keepsEntriesOfOneSource() {
        let filter = LogFilter(source: .engine)

        #expect(filter.matches(Self.engineError))
        #expect(!filter.matches(Self.appInfo))
    }

    @Test
    func findsTextWhateverItsCase() {
        let filter = LogFilter(searchText: "  handshake ")

        #expect(filter.matches(Self.engineError))
        #expect(!filter.matches(Self.appInfo))
    }

    @Test
    func restrictsLevelOrSourceOnlyWhenEitherDiffersFromTheDefault() {
        #expect(!LogFilter().restrictsLevelOrSource)
        #expect(!LogFilter(searchText: "handshake").restrictsLevelOrSource)
        #expect(LogFilter(minimumLevel: .warning).restrictsLevelOrSource)
        #expect(LogFilter(source: .engine).restrictsLevelOrSource)
    }
}
