import RoutingProbeCore
import Testing

@Suite
struct MedianTests {
    @Test
    func takesTheMiddleOfAnOddCount() {
        #expect([3.0, 1.0, 2.0].median == 2)
    }

    @Test
    func averagesTheTwoMiddleValuesOfAnEvenCount() {
        #expect([4.0, 1.0, 3.0, 2.0].median == 2.5)
    }

    @Test
    func hasNoMedianWithoutValues() {
        #expect([Double]().median == nil)
    }
}
