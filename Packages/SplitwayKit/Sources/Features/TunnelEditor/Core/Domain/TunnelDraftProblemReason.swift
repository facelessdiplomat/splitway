import TunnelConfiguration
import TunnelLibrary

public enum TunnelDraftProblemReason: Sendable, Equatable {
    case missing
    case invalidName(TunnelNameError)
    case invalidValue(ConfigurationValueError)
    case duplicatePeerPublicKey
}
