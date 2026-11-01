import WidgetKit

struct SpikeVPNValueProvider: ControlValueProvider {
    var previewValue: Bool {
        false
    }

    func currentValue() async throws -> Bool {
        await SpikeVPN.isActive()
    }
}
