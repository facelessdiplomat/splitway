package servicerouting

import "time"

const (
	transitoryTCPTimeout      = 4 * time.Minute
	establishedTCPTimeout     = 2*time.Hour + 4*time.Minute
	udpMappingTimeout         = 5 * time.Minute
	maximumTrackedConnections = 4096
)

type connectionClass uint8

const (
	transitoryTCPConnection connectionClass = iota
	establishedTCPConnection
	udpMapping
	connectionClassCount
)

func (class connectionClass) timeout() time.Duration {
	switch class {
	case establishedTCPConnection:
		return establishedTCPTimeout
	case udpMapping:
		return udpMappingTimeout
	}
	return transitoryTCPTimeout
}
