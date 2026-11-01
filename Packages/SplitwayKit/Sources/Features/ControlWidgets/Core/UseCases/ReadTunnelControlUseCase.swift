import Shortcuts
import TunnelConnection
import TunnelLibrary

public struct ReadTunnelControlUseCase: Sendable {
    private let readSlotState: ReadSlotStateUseCase
    private let records: any TunnelRecordRepository

    public init(readSlotState: ReadSlotStateUseCase, records: any TunnelRecordRepository) {
        self.readSlotState = readSlotState
        self.records = records
    }

    public func execute(selection: TunnelIdentifier?) async throws(TunnelShortcutError) -> TunnelControlSnapshot {
        let library: [TunnelRecord]
        do {
            library = try await records.loadRecords()
        } catch {
            throw .libraryUnavailable
        }
        return TunnelControlSnapshot(selection: selection, slot: await readSlotState.execute(), records: library)
    }
}
